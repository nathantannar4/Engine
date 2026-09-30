//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine
@testable import EngineCore

/// Micro-benchmarks for hot paths that are not covered by render benchmarks
@MainActor
final class HotPathBenchmarkTests: XCTestCase {

    func measureTime(
        _ name: String,
        iterations: Int,
        _ body: () -> Void
    ) -> TimeInterval {
        // Warm up any caches, so steady state performance is measured
        body()
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            body()
        }
        let time = (CFAbsoluteTimeGetCurrent() - start) / Double(iterations)
        print("BENCH \(name): \(String(format: "%.4f", time * 1_000))ms")
        return time
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testConcatenatedTextResolve() {
        let text = (0..<50).reduce(Text("")) { result, index in
            result + Text(verbatim: "\(index) ").bold()
        }
        let environment = EnvironmentValues()
        var output: NSAttributedString?
        _ = measureTime("Text (50 concatenated) NSAttributedString", iterations: 50) {
            output = text.resolveNSAttributedString(in: environment)
        }
        XCTAssertEqual(output?.string, (0..<50).map { "\($0) " }.joined())
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            var attributedString: AttributedString?
            _ = measureTime("Text (50 concatenated) AttributedString", iterations: 50) {
                attributedString = text.resolveAttributedString(in: environment)
            }
            XCTAssertEqual(attributedString.map { String($0.characters) }, output?.string)
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testLocalizedTextResolve() {
        let text = Text("Hello, \("World") and \(42)")
        let environment = EnvironmentValues()
        var output: NSAttributedString?
        _ = measureTime("Text (localized with arguments) NSAttributedString", iterations: 500) {
            output = text.resolveNSAttributedString(in: environment)
        }
        XCTAssertEqual(output?.string, "Hello, World and 42")
    }

    func testFontResolve() {
        let font = Font.system(size: 17).bold().italic()
        let environment = EnvironmentValues()
        _ = measureTime("Font (modified) toPlatformValue", iterations: 2_000) {
            _ = font.toPlatformValue(in: environment)
        }
    }

    func testMultiViewVisitCustomViews() {
        struct Leaf: View {
            var index: Int
            var body: some View {
                Text(index.description)
            }
        }
        struct Pair: View {
            var index: Int
            var body: some View {
                Leaf(index: index)
                Leaf(index: index + 1)
            }
        }
        struct Quad: View {
            var index: Int
            var body: some View {
                Pair(index: index)
                Pair(index: index + 2)
            }
        }
        struct Oct: View {
            var index: Int
            var body: some View {
                Quad(index: index)
                Quad(index: index + 4)
            }
        }
        let content = ForEach(0..<50, id: \.self) { index in
            Oct(index: index * 8)
        }
        var count = 0
        _ = measureTime("MultiViewSubviewVisitor (50 x 3-level nested custom views)", iterations: 20) {
            var visitor = MultiViewSubviewVisitor()
            content.visit(visitor: &visitor)
            count = visitor.subviews.count
        }
        XCTAssertEqual(count, 400)
    }
}
