//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine
import EngineCore

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ImageTests: XCTestCase {

    // MARK: - SymbolRenderingMode storage layout

    /// SwiftUI's internal `SymbolRenderingMode.Storage` keeps the four public
    /// modes at tags 0...3, matching `SymbolRenderingModeStorage`'s raw values.
    func testSymbolRenderingModeStorage() {
        XCTAssertEqual(SymbolRenderingMode.monochrome.storage, .monochrome)
        XCTAssertEqual(SymbolRenderingMode.multicolor.storage, .multicolor)
        XCTAssertEqual(SymbolRenderingMode.hierarchical.storage, .hierarchical)
        XCTAssertEqual(SymbolRenderingMode.palette.storage, .palette)
    }

    /// `SymbolRenderingMode?.none` is encoded as an extra inhabitant tag equal to
    /// SwiftUI's internal case count (5 on iOS 17, 8 on iOS 18, 9 on iOS/macOS 27),
    /// so it must never decode as one of Engine's cases.
    func testOptionalSymbolRenderingModeNilTag() {
        let mode: SymbolRenderingMode? = nil
        let tag = withUnsafeBytes(of: mode) { $0[0] }
        XCTAssertGreaterThanOrEqual(tag, 4)
        XCTAssertNil(SymbolRenderingModeStorage(rawValue: tag))
    }

    func testImageSymbolRenderingModeTag() throws {
        let image = Image(systemName: "star.fill")
        XCTAssertNil(try renderingModeTag(of: image.symbolRenderingMode(nil)).flatMap(SymbolRenderingModeStorage.init(rawValue:)))
        XCTAssertEqual(try renderingModeTag(of: image.symbolRenderingMode(.monochrome)), SymbolRenderingModeStorage.monochrome.rawValue)
        XCTAssertEqual(try renderingModeTag(of: image.symbolRenderingMode(.multicolor)), SymbolRenderingModeStorage.multicolor.rawValue)
        XCTAssertEqual(try renderingModeTag(of: image.symbolRenderingMode(.hierarchical)), SymbolRenderingModeStorage.hierarchical.rawValue)
        XCTAssertEqual(try renderingModeTag(of: image.symbolRenderingMode(.palette)), SymbolRenderingModeStorage.palette.rawValue)
    }

    // MARK: - Resolution

    /// A nil explicit mode must fall back to the environment's mode rather than
    /// being decoded as a bogus explicit mode.
    func testNilSymbolRenderingModeFallsBackToEnvironment() throws {
        guard #available(iOS 16.0, macOS 14.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Requires symbol configuration introspection")
        }
        for mode in [SymbolRenderingMode.monochrome, .multicolor, .hierarchical] {
            var environment = EnvironmentValues()
            environment.symbolRenderingMode = mode
            let expected = try XCTUnwrap(symbolConfiguration(of: Image(systemName: "star.fill"), in: environment))
            let resolved = try XCTUnwrap(symbolConfiguration(of: Image(systemName: "star.fill").symbolRenderingMode(nil), in: environment))
            XCTAssertEqual(resolved, expected, "\(mode)")
        }
    }

    /// An explicit mode on the image resolves the same as that mode in the environment.
    @available(iOS 16.0, macOS 14.0, tvOS 16.0, watchOS 9.0, *)
    func testExplicitSymbolRenderingMode() throws {
        let assertions = {
            for mode in [SymbolRenderingMode.monochrome, .multicolor, .hierarchical] {
                var environment = EnvironmentValues()
                environment.symbolRenderingMode = mode
                let expected = try XCTUnwrap(self.symbolConfiguration(of: Image(systemName: "star.fill"), in: environment))
                let resolved = try XCTUnwrap(self.symbolConfiguration(of: Image(systemName: "star.fill").symbolRenderingMode(mode), in: EnvironmentValues()))
                XCTAssertEqual(resolved, expected, "\(mode)")
            }
        }
        if try symbolRenderingModeProviderName() == "SymbolRenderingModeProvider" {
            // Known gap: Engine does not read `SymbolRenderingModeProvider`, so explicit modes
            // are dropped on iOS 17/18. Strict, so this flags once that provider is supported.
            try XCTExpectFailure("Engine does not read SymbolRenderingModeProvider") {
                try assertions()
            }
        } else {
            try assertions()
        }
    }

    // MARK: - Helpers

    /// The provider `Image.symbolRenderingMode(_:)` creates:
    /// `SymbolRenderingModeProvider` before iOS 26 / macOS 26, `SymbolRenderingOptionsProvider` after.
    private func symbolRenderingModeProviderName() throws -> String {
        let provider = try swift_getFieldValue("provider", Any.self, Image(systemName: "star.fill").symbolRenderingMode(nil))
        let base = try swift_getFieldValue("base", Any.self, provider)
        return String(describing: type(of: base))
    }

    /// Reads the raw `SymbolRenderingMode.Storage?` tag from the image's provider.
    private func renderingModeTag(of image: Image) throws -> UInt8? {
        let provider = try swift_getFieldValue("provider", Any.self, image)
        let base = try swift_getFieldValue("base", Any.self, provider)
        switch String(describing: type(of: base)) {
        case "SymbolRenderingOptionsProvider":
            let options = try swift_getFieldValue("options", Any.self, base)
            return try swift_getFieldValue("renderingMode", UInt8.self, options)
        case "SymbolRenderingModeProvider":
            return try swift_getFieldValue("mode", UInt8.self, base)
        case let name:
            XCTFail("Unexpected provider \(name)")
            return nil
        }
    }

    @available(iOS 16.0, macOS 14.0, tvOS 16.0, watchOS 9.0, *)
    private func symbolConfiguration(of image: Image, in environment: EnvironmentValues) -> Image.PlatformRepresentable.SymbolConfiguration? {
        image.toPlatformValue(in: environment)?.symbolConfiguration
    }
}
