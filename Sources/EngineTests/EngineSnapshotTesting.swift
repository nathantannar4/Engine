//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// A lightweight snapshot testing helper that renders a SwiftUI view with `ImageRenderer`
/// and compares the result against a reference PNG stored alongside the test file.
///
/// Reference images are stored per platform and major OS version, since SwiftUI
/// rendering is not stable across releases:
///
///     Sources/EngineTests/__Snapshots__/<platform>-<major>/<TestFile>/<test>.<name>.png
///
/// - When a reference image is missing it is recorded and the test fails, so the new
///   reference can be reviewed and committed. If the `CI` environment variable is set
///   the test is skipped instead, so OS versions without references don't fail CI.
/// - Set the `SNAPSHOT_RECORD` environment variable (or `TEST_RUNNER_SNAPSHOT_RECORD`
///   when running through `xcodebuild`) to re-record all reference images.
/// - On failure the rendered and diff images are attached to the test result and written
///   to a temporary directory.
@MainActor
enum SnapshotTesting {

    static var isRecording: Bool {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] != nil
    }

    static var isRunningOnCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil
    }

    static var platformDirectoryName: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        #if targetEnvironment(macCatalyst)
        return "macCatalyst-\(version)"
        #elseif os(iOS)
        return "iOS-\(version)"
        #elseif os(macOS)
        return "macOS-\(version)"
        #elseif os(tvOS)
        return "tvOS-\(version)"
        #elseif os(watchOS)
        return "watchOS-\(version)"
        #elseif os(visionOS)
        return "visionOS-\(version)"
        #else
        return "unknown-\(version)"
        #endif
    }
}

/// Asserts that the rendered `view` matches the recorded reference image.
///
/// - Parameters:
///   - view: The view to render.
///   - name: An optional name to distinguish multiple snapshots within the same test.
///   - size: The size proposed to and enforced on the view.
///   - colorScheme: The color scheme the view is rendered with.
///   - scale: The scale the view is rendered with.
///   - precision: The fraction of pixels that must match, from 0 to 1.
///   - perPixelTolerance: The maximum difference allowed per color channel for a pixel to match, from 0 to 1.
@MainActor
func assertSnapshot<Content: View>(
    of view: Content,
    named name: String? = nil,
    size: CGSize,
    colorScheme: ColorScheme = .light,
    scale: CGFloat = 2,
    precision: Double = 0.995,
    perPixelTolerance: Double = 0.02,
    filePath: StaticString = #filePath,
    function: String = #function,
    line: UInt = #line
) throws {
    #if !os(iOS) || targetEnvironment(macCatalyst)
    throw XCTSkip("Snapshot testing is only supported on iOS")
    #else
    guard #available(iOS 16.0, *) else {
        throw XCTSkip("Snapshot testing requires ImageRenderer")
    }

    let testName = function.replacingOccurrences(of: "()", with: "")
    let fileName = (name.map { "\(testName).\($0)" } ?? testName) + ".png"
    let testFileURL = URL(fileURLWithPath: "\(filePath)")
    let referenceURL = testFileURL
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(SnapshotTesting.platformDirectoryName)
        .appendingPathComponent(testFileURL.deletingPathExtension().lastPathComponent)
        .appendingPathComponent(fileName)

    let content = view
        .frame(width: size.width, height: size.height)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .environment(\.colorScheme, colorScheme)
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en_US"))
        .environment(\.dynamicTypeSize, .large)
    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    renderer.proposedSize = ProposedViewSize(size)
    guard let rendered = renderer.cgImage.flatMap(SnapshotBitmap.init) else {
        XCTFail("Failed to render snapshot \(fileName)", file: filePath, line: line)
        return
    }

    let referenceExists = FileManager.default.fileExists(atPath: referenceURL.path)
    if SnapshotTesting.isRecording || !referenceExists {
        if !referenceExists, SnapshotTesting.isRunningOnCI {
            throw XCTSkip("Missing reference snapshot for \(SnapshotTesting.platformDirectoryName): \(fileName)")
        }
        try FileManager.default.createDirectory(
            at: referenceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try rendered.pngData().write(to: referenceURL)
        XCTFail(
            "Recorded reference snapshot at \(referenceURL.path). Re-run the test to compare against it.",
            file: filePath,
            line: line
        )
        return
    }

    guard let reference = SnapshotBitmap(contentsOf: referenceURL) else {
        XCTFail("Failed to load reference snapshot at \(referenceURL.path)", file: filePath, line: line)
        return
    }

    guard reference.width == rendered.width, reference.height == rendered.height else {
        try attachFailure(rendered: rendered, diff: nil, fileName: fileName)
        XCTFail(
            "Snapshot size \(rendered.width)x\(rendered.height) does not match reference size \(reference.width)x\(reference.height)",
            file: filePath,
            line: line
        )
        return
    }

    let comparison = rendered.compare(to: reference, perPixelTolerance: perPixelTolerance)
    if comparison.matchingFraction < precision {
        try attachFailure(rendered: rendered, diff: comparison.diff, fileName: fileName)
        XCTFail(
            String(
                format: "Snapshot does not match reference %@: %.2f%% of pixels match, %.2f%% required",
                referenceURL.path,
                comparison.matchingFraction * 100,
                precision * 100
            ),
            file: filePath,
            line: line
        )
    }
    #endif
}

@MainActor
private func attachFailure(
    rendered: SnapshotBitmap,
    diff: SnapshotBitmap?,
    fileName: String
) throws {
    let failureDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("EngineSnapshotFailures")
        .appendingPathComponent(SnapshotTesting.platformDirectoryName)
    try FileManager.default.createDirectory(at: failureDirectory, withIntermediateDirectories: true)

    var images = [("actual", rendered)]
    if let diff {
        images.append(("diff", diff))
    }
    for (kind, bitmap) in images {
        let data = try bitmap.pngData()
        let url = failureDirectory.appendingPathComponent(
            fileName.replacingOccurrences(of: ".png", with: ".\(kind).png")
        )
        try data.write(to: url)

        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = url.lastPathComponent
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Snapshot \(kind)") { activity in
            activity.add(attachment)
        }
    }
    print("Snapshot failure images written to \(failureDirectory.path)")
}

/// An 8-bit RGBA, premultiplied, sRGB bitmap so that rendered and decoded images
/// are compared in the same format.
struct SnapshotBitmap {

    var width: Int
    var height: Int
    var pixels: [UInt8]

    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    init?(_ image: CGImage) {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: Self.colorSpace,
                bitmapInfo: Self.bitmapInfo
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw else { return nil }
        self.init(width: width, height: height, pixels: pixels)
    }

    init?(contentsOf url: URL) {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return nil
        }
        self.init(image)
    }

    func cgImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
            return nil
        }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: Self.colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: Self.bitmapInfo),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    func pngData() throws -> Data {
        let data = NSMutableData()
        guard
            let image = cgImage(),
            let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)
        else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data as Data
    }

    /// Compares two bitmaps of equal size, returning the fraction of matching pixels
    /// and an image highlighting mismatched pixels in red.
    func compare(
        to reference: SnapshotBitmap,
        perPixelTolerance: Double
    ) -> (matchingFraction: Double, diff: SnapshotBitmap) {
        precondition(width == reference.width && height == reference.height)
        let threshold = Int((perPixelTolerance * 255).rounded())
        let pixelCount = width * height
        var diffPixels = [UInt8](repeating: 0, count: pixelCount * 4)
        var mismatchCount = 0
        for pixel in 0..<pixelCount {
            let offset = pixel * 4
            var isMatch = true
            for channel in 0..<4 where abs(Int(pixels[offset + channel]) - Int(reference.pixels[offset + channel])) > threshold {
                isMatch = false
                break
            }
            if isMatch {
                // Faded reference pixel for context
                for channel in 0..<3 {
                    diffPixels[offset + channel] = UInt8(Int(reference.pixels[offset + channel]) / 4)
                }
                diffPixels[offset + 3] = 255
            } else {
                mismatchCount += 1
                diffPixels[offset] = 255
                diffPixels[offset + 3] = 255
            }
        }
        let matchingFraction = pixelCount == 0 ? 1 : Double(pixelCount - mismatchCount) / Double(pixelCount)
        return (matchingFraction, SnapshotBitmap(width: width, height: height, pixels: diffPixels))
    }
}
