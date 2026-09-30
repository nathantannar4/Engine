//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class SnapshotTests: XCTestCase {

    let size = CGSize(width: 120, height: 80)

    // MARK: - Shapes

    func testRoundedCornersRectangle() throws {
        try assertSnapshot(
            of: RoundedCornersRectangle(
                topLeadingRadius: 4,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 24,
                topTrailingRadius: 36
            )
            .fill(Color.blue)
            .padding(8),
            size: size
        )
    }

    func testRoundedCornersRectangleInset() throws {
        try assertSnapshot(
            of: RoundedCornersRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
            .strokeBorder(Color.red, lineWidth: 6)
            .padding(8),
            size: size
        )
    }

    func testCapsuleRoundedRectangle() throws {
        try assertSnapshot(
            of: VStack(spacing: 8) {
                CapsuleRoundedRectangle(maxCornerRadius: nil)
                    .fill(Color.green)
                CapsuleRoundedRectangle(maxCornerRadius: 6)
                    .fill(Color.orange)
            }
            .padding(8),
            size: size
        )
    }

    func testInsetShape() throws {
        try assertSnapshot(
            of: ZStack {
                Rectangle()
                    .fill(Color.gray)
                Circle()
                    .inset(dx: 10, dy: 10)
                    .fill(Color.purple)
                Rectangle()
                    .inset(by: EdgeInsets(top: 30, leading: 5, bottom: 30, trailing: 5))
                    .fill(Color.yellow)
            },
            size: size
        )
    }

    func testLine() throws {
        try assertSnapshot(
            of: ZStack {
                Line(
                    startPoint: .leading,
                    endPoint: .trailing,
                    strokeStyle: StrokeStyle(lineWidth: 2)
                )
                .fill(Color.black)

                Line(
                    startPoint: .bottomLeading,
                    endPoint: .bottomTrailing,
                    segments: [
                        .curve(controlPoint1: .top, controlPoint2: .top),
                    ],
                    strokeStyle: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .fill(Color.blue)

                Line(
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    segments: [
                        .linear(point: .center),
                    ],
                    strokeStyle: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .fill(Color.red)
            }
            .padding(8),
            size: size
        )
    }

    func testShapeBuilderClipShape() throws {
        func content(isCircle: Bool) -> some View {
            Color(red: 0.2, green: 0.7, blue: 0.7)
                .clipShape {
                    if isCircle {
                        Circle()
                    } else {
                        RoundedCornersRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                    }
                }
        }
        try assertSnapshot(
            of: HStack(spacing: 8) {
                content(isCircle: true)
                content(isCircle: false)
            }
            .padding(8),
            size: size
        )
    }

    // MARK: - Modifiers

    func testInvertedMask() throws {
        try assertSnapshot(
            of: Color(red: 0.3, green: 0.3, blue: 0.8)
                .invertedMask {
                    Circle()
                        .frame(width: 40, height: 40)
                },
            size: size
        )
    }

    // MARK: - Views

    func testVariadicViewAdapter() throws {
        try assertSnapshot(
            of: VariadicViewAdapter {
                Color.red
                Color.green
                Color.blue
            } content: { source in
                HStack(spacing: 4) {
                    ForEachSubview(source) { index, subview in
                        subview
                            .frame(width: CGFloat(index + 1) * 16)
                    }
                }
            }
            .padding(8),
            size: size
        )
    }

    func testStaticConditionalContent() throws {
        try assertSnapshot(
            of: HStack(spacing: 8) {
                StaticConditionalContent(TrueStaticCondition.self) {
                    Color.green
                } otherwise: {
                    Color.red
                }
                StaticConditionalContent(FalseStaticCondition.self) {
                    Color.red
                } otherwise: {
                    Color.green
                }
            }
            .padding(8),
            size: size
        )
    }

    func testViewStyle() throws {
        try assertSnapshot(
            of: VStack(spacing: 8) {
                SnapshotSwatch(color: .blue)
                SnapshotSwatch(color: .blue)
                    .snapshotSwatchStyle(CircleSnapshotSwatchStyle())
                SnapshotSwatch(color: .blue)
                    .snapshotSwatchStyle(BorderedSnapshotSwatchStyle()) // Applied 1st
                    .snapshotSwatchStyle(CircleSnapshotSwatchStyle()) // Applied 2nd
            }
            .padding(4),
            size: CGSize(width: 80, height: 120)
        )
    }

    func testConditionalView() throws {
        try assertSnapshot(
            of: HStack(spacing: 8) {
                ConditionalView(if: true) {
                    Color.green
                } otherwise: {
                    Color.red
                }
                ConditionalView(if: false) {
                    Color.red
                } otherwise: {
                    Color.green
                }
                // Missing branch resolves to EmptyView
                ConditionalView(if: false) {
                    Color.red
                }
            }
            .padding(8),
            size: size
        )
    }

    func testOptionalAdapter() throws {
        try assertSnapshot(
            of: HStack(spacing: 8) {
                OptionalAdapter(Optional<Color>.some(.green)) { color in
                    color
                } placeholder: {
                    Color.red
                }
                OptionalAdapter(Optional<Color>.none) { color in
                    color
                } placeholder: {
                    Color.gray
                }
                OptionalAdapter(Optional<Color>.some(.blue), Optional<CGFloat>.some(8)) { color, radius in
                    RoundedRectangle(cornerRadius: radius)
                        .fill(color)
                } placeholder: {
                    Color.red
                }
            }
            .padding(8),
            size: size
        )
    }

    func testViewStackAxisReader() throws {
        try assertSnapshot(
            of: VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Color.gray
                    // Vertical red line
                    SnapshotStackAxisDivider()
                    Color.gray
                }
                // Horizontal blue line
                SnapshotStackAxisDivider()
                ZStack {
                    Color.gray
                    // Green dot, neither in a VStack or HStack
                    SnapshotStackAxisDivider()
                }
            }
            .padding(8),
            size: size
        )
    }

    func testFirstTextMidlineAlignment() throws {
        try assertSnapshot(
            of: HStack(alignment: .firstTextMidline, spacing: 4) {
                Color.red
                    .frame(width: 8, height: 8)
                Text("Line 1\nLine 2")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .padding(8),
            size: size,
            // Text anti-aliasing varies slightly between OS minor versions
            precision: 0.98,
            perPixelTolerance: 0.05
        )
    }

    func testVersionedView() throws {
        // Resolves to the newest implemented body available on the running OS
        try assertSnapshot(
            of: SnapshotVersionedView()
                .padding(8),
            size: size
        )
        try assertVersionedSnapshots(
            of: SnapshotVersionedView()
                .padding(8)
        )
    }

    func testVersionedViewModifier() throws {
        // Resolves to the newest implemented body available on the running OS
        try assertSnapshot(
            of: Color.white
                .modifier(SnapshotVersionedViewModifier())
                .padding(8),
            size: size
        )
        try assertVersionedSnapshots(
            of: Color.white
                .modifier(SnapshotVersionedViewModifier())
                .padding(8)
        )
    }

    /// Snapshots `content` with every ``VersionInput`` available on the running OS
    private func assertVersionedSnapshots<Content: View>(
        of content: Content,
        filePath: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) throws {
        func assert<V: View>(_ view: V, named name: String) throws {
            try assertSnapshot(
                of: view,
                named: name,
                size: size,
                filePath: filePath,
                function: function,
                line: line
            )
        }
        if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
            try assert(content.version(.v8_1), named: "v8_1")
        }
        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
            try assert(content.version(.v8), named: "v8")
        }
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            try assert(content.version(.v7), named: "v7")
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            try assert(content.version(.v6), named: "v6")
        }
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            try assert(content.version(.v5), named: "v5")
        }
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            try assert(content.version(.v4), named: "v4")
        }
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            try assert(content.version(.v3), named: "v3")
        }
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            try assert(content.version(.v2), named: "v2")
        }
        try assert(content.version(.v1), named: "v1")
    }

    func testViewAlias() throws {
        try assertSnapshot(
            of: HStack(spacing: 8) {
                // Resolved by the ancestor
                SnapshotRow()
                    .viewAlias(SnapshotRow.Content.self) {
                        Circle()
                            .fill(Color.green)
                    }
                // Falls back to the default body
                SnapshotRow()
            }
            .padding(8),
            size: size
        )
    }

    func testMultiViewAdapter() throws {
        try assertSnapshot(
            of: MultiViewAdapter {
                Color.red
                Group {
                    Color.green
                    Color.blue
                }
                ForEach(0..<2, id: \.self) { _ in
                    Color.orange
                }
            } content: { subviews in
                HStack(spacing: 4) {
                    ForEachSubview(subviews) { index, subview in
                        subview
                            .frame(height: CGFloat(index + 1) * 12)
                    }
                }
            }
            .padding(8),
            size: size
        )
    }

    func testUnaryViewAdaptor() throws {
        // The unary view is laid out as a single subview, so the
        // VStack is stacked within one HStack subview
        try assertSnapshot(
            of: VariadicViewAdapter {
                Color.red
                UnaryViewAdaptor {
                    Color.green
                    Color.blue
                }
            } content: { source in
                HStack(spacing: 4) {
                    ForEachSubview(source) { _, subview in
                        VStack(spacing: 4) {
                            subview
                        }
                    }
                }
            }
            .padding(8),
            size: size
        )
    }

    // MARK: - Layouts

    func testLayoutThatFits() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Layout requires iOS 16")
        }
        func content(width: CGFloat) -> some View {
            LayoutThatFits(in: .horizontal, HStackLayout(spacing: 4), VStackLayout(spacing: 4)) {
                Color.red.frame(width: 24, height: 16)
                Color.green.frame(width: 24, height: 16)
                Color.blue.frame(width: 24, height: 16)
            }
            .frame(width: width)
            .border(Color.gray)
        }
        try assertSnapshot(
            of: HStack(alignment: .top, spacing: 8) {
                // Fits horizontally
                content(width: 80)
                // Falls back to vertical
                content(width: 24)
            }
            .padding(8),
            size: CGSize(width: 140, height: 80)
        )
    }

    func testLayoutAdapter() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Layout requires iOS 16")
        }
        func content(isHorizontal: Bool) -> some View {
            LayoutAdapter {
                if isHorizontal {
                    HStackLayout(spacing: 4)
                } else {
                    VStackLayout(spacing: 4)
                }
            } content: {
                Color.red
                Color.green
                Color.blue
            }
        }
        try assertSnapshot(
            of: HStack(spacing: 8) {
                content(isHorizontal: true)
                content(isHorizontal: false)
            }
            .padding(8),
            size: size
        )
    }

    // MARK: - Geometry Effects

    func testOffsetEffect() throws {
        try assertSnapshot(
            of: ZStack {
                Color.gray
                    .frame(width: 24, height: 24)
                Color.red
                    .frame(width: 24, height: 24)
                    .offset(x: 0, y: 0, anchor: .trailing)
                Color.blue
                    .frame(width: 24, height: 24)
                    .offset(x: 4, y: 0, anchor: .top)
            },
            size: size
        )
    }

    func testScaleEffect() throws {
        try assertSnapshot(
            of: HStack(spacing: 8) {
                Color.gray
                    .overlay(
                        Color.red
                            .modifier(ScaleEffect(scale: 0.5, anchor: .topLeading))
                    )
                Color.gray
                    .overlay(
                        Color.green
                            .modifier(ScaleEffect(x: 1, y: 0.25, anchor: .bottom))
                    )
                Color.gray
                    .overlay(
                        Color.blue
                            .modifier(ScaleEffect(x: 0.5, y: 0.5))
                    )
            }
            .padding(8),
            size: size
        )
    }

    func testRotationEffect() throws {
        try assertSnapshot(
            of: HStack(spacing: 24) {
                Color.red
                    .frame(width: 24, height: 24)
                    .modifier(RotationEffect(angle: .degrees(45)))
                Color.blue
                    .frame(width: 24, height: 24)
                    .modifier(RotationEffect(angle: .degrees(30), anchor: .topLeading))
            }
            .padding(8),
            size: size
        )
    }

    func testAlignmentGuideOffset() throws {
        try assertSnapshot(
            of: Color.gray
                .frame(width: 64, height: 48)
                .overlay(
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        // Center the badge on the top trailing corner
                        .alignmentGuideOffset(alignment: .topTrailing, anchor: UnitPoint(x: 0.5, y: 0.5)),
                    alignment: .topTrailing
                )
                .overlay(
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .alignmentGuideOffset(alignment: .bottomLeading, x: -4, y: -4),
                    alignment: .bottomLeading
                ),
            size: size
        )
    }

    // MARK: - Shape Wrappers

    func testShapeWrappers() throws {
        let isRounded = true
        try assertSnapshot(
            of: HStack(spacing: 4) {
                ConditionalShape<Circle, Rectangle>(Circle())
                    .fill(Color.red)
                OptionalShape(Optional<Capsule>.some(Capsule()))
                    .fill(Color.green)
                // Renders nothing
                OptionalShape(Optional<Circle>.none)
                    .fill(Color.red)
                ConditionalShape<Circle, Rectangle>(Rectangle())
                    .fill(Color.blue)
                EmptyShape()
                    .fill(Color.red)
                ShapeAdapter {
                    if isRounded {
                        RoundedCornersRectangle(topLeadingRadius: 8, bottomTrailingRadius: 8)
                    } else {
                        Rectangle()
                    }
                }
                .fill(Color.orange)
            }
            .padding(8),
            size: size
        )
    }

    func testInsettableShapeWrappers() throws {
        try assertSnapshot(
            of: HStack(spacing: 4) {
                ConditionalShape<Circle, Rectangle>(Circle())
                    .strokeBorder(Color.red, lineWidth: 4)
                OptionalShape(Optional<Capsule>.some(Capsule()))
                    .strokeBorder(Color.green, lineWidth: 4)
                ConditionalShape<Circle, Rectangle>(Rectangle())
                    .strokeBorder(Color.blue, lineWidth: 4)
            }
            .padding(8),
            size: size
        )
    }

    // MARK: - Environment

    func testInvertColorScheme() throws {
        let content = HStack(spacing: 8) {
            Color.primary
            Color.primary
                .invertColorScheme()
            Color.primary
                .invertColorScheme(isEnabled: false)
        }
        .padding(8)
        try assertSnapshot(of: content, named: "light", size: size, colorScheme: .light)
        try assertSnapshot(of: content, named: "dark", size: size, colorScheme: .dark)
    }

    func testColorScheme() throws {
        let content = VStack(spacing: 8) {
            RoundedCornersRectangle(topLeadingRadius: 12, bottomTrailingRadius: 12)
                .fill(Color.primary)
            CapsuleRoundedRectangle(maxCornerRadius: nil)
                .fill(Color.accentColor)
        }
        .padding(8)
        try assertSnapshot(of: content, named: "light", size: size, colorScheme: .light)
        try assertSnapshot(of: content, named: "dark", size: size, colorScheme: .dark)
    }

    // MARK: - Text

    func testText() throws {
        try assertSnapshot(
            of: Text("Engine")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black),
            size: size,
            // Text anti-aliasing varies slightly between OS minor versions
            precision: 0.98,
            perPixelTolerance: 0.05
        )
    }
}

// MARK: - ViewStyle

private protocol SnapshotSwatchStyle: ViewStyle where Configuration == SnapshotSwatchStyleConfiguration {
    associatedtype Configuration = Configuration
}

private struct SnapshotSwatchStyleConfiguration {
    var color: Color
}

private struct SnapshotSwatch: ViewStyledView {
    var configuration: SnapshotSwatchStyleConfiguration

    init(color: Color) {
        self.configuration = .init(color: color)
    }

    init(_ configuration: SnapshotSwatchStyleConfiguration) {
        self.configuration = configuration
    }

    static var defaultStyle: DefaultSnapshotSwatchStyle { DefaultSnapshotSwatchStyle() }
}

private struct DefaultSnapshotSwatchStyle: SnapshotSwatchStyle {
    func makeBody(configuration: SnapshotSwatchStyleConfiguration) -> some View {
        Rectangle()
            .fill(configuration.color)
    }
}

private struct CircleSnapshotSwatchStyle: SnapshotSwatchStyle {
    func makeBody(configuration: SnapshotSwatchStyleConfiguration) -> some View {
        Circle()
            .fill(configuration.color)
    }
}

private struct BorderedSnapshotSwatchStyle: SnapshotSwatchStyle {
    func makeBody(configuration: SnapshotSwatchStyleConfiguration) -> some View {
        SnapshotSwatch(configuration)
            .padding(2)
            .border(Color.red, width: 2)
    }
}

extension View {
    fileprivate func snapshotSwatchStyle<Style: SnapshotSwatchStyle>(_ style: Style) -> some View {
        styledViewStyle(SnapshotSwatch.self, style: style)
    }
}

// MARK: - ViewStackAxisReader

private struct SnapshotStackAxisDivider: View {
    var body: some View {
        ViewStackAxisReader {
            Color.blue
                .frame(height: 4)
        } horizontal: {
            Color.red
                .frame(width: 4)
        } other: {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
        }
    }
}

// MARK: - VersionedView

/// Renders a distinct color per version, so the snapshot of each
/// OS captures which body was resolved.
private struct SnapshotVersionedView: VersionedView {

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    var v8_1Body: some View {
        Color.pink
    }

    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    var v8Body: some View {
        Color.purple
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    var v7Body: some View {
        Color.blue
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    var v6Body: some View {
        Color.green
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    var v5Body: some View {
        Color.yellow
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    var v4Body: some View {
        Color.orange
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var v3Body: some View {
        Color.gray
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var v2Body: some View {
        Color.black
    }

    var v1Body: some View {
        Color.red
    }
}

private struct SnapshotVersionedViewModifier: VersionedViewModifier {

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    func v8_1Body(content: Content) -> some View {
        content.border(Color.pink, width: 8)
    }

    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    func v8Body(content: Content) -> some View {
        content.border(Color.purple, width: 8)
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func v7Body(content: Content) -> some View {
        content.border(Color.blue, width: 8)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func v6Body(content: Content) -> some View {
        content.border(Color.green, width: 8)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func v5Body(content: Content) -> some View {
        content.border(Color.yellow, width: 8)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func v4Body(content: Content) -> some View {
        content.border(Color.orange, width: 8)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func v3Body(content: Content) -> some View {
        content.border(Color.gray, width: 8)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func v2Body(content: Content) -> some View {
        content.border(Color.black, width: 8)
    }

    func v1Body(content: Content) -> some View {
        content.border(Color.red, width: 8)
    }
}

// MARK: - ViewAlias

private struct SnapshotRow: View {
    struct Content: ViewAlias {
        var defaultBody: some View {
            Rectangle()
                .fill(Color.gray)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Color.blue
                .frame(height: 12)
            Content()
        }
    }
}
