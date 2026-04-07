//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class BenchmarkTests: XCTestCase {

    func measureRender<Content: View>(
        iterations: Int = 1,
        @ViewBuilder content: () -> Content
    ) -> TimeInterval {
        var time: TimeInterval = 0
        for _ in (0..<iterations) {
            let host = HostingView(content: content())
            time += host.measureRender()
        }
        return time / Double(iterations)
    }

    func testAnyView() {
        let anyViewRenderTime = measureRender(iterations: 1_000) {
            AnyView(Text("Hello, World!"))
        }
        let staticViewRenderTime = measureRender(iterations: 1_000) {
            Text("Hello, World!")
        }
        print("AnyView: \(anyViewRenderTime) vs. \(staticViewRenderTime)") // 0.246ms vs. 0.201ms
        XCTAssertGreaterThan(anyViewRenderTime, staticViewRenderTime)
    }

    func testVersionedView() {
        struct ViewBuilderVersionedView: View {
            var body: some View {
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                    Text("Version >= 5")
                } else {
                    Text("Version < 5")
                }
            }
        }
        struct EngineVersionedView: VersionedView {
            var v1Body: some View {
                Text("Version < 5")
            }

            @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
            var v5Body: some View {
                Text("Version >= 5")
            }
        }

        let viewBuilderRenderTime = measureRender(iterations: 100) {
            ViewBuilderVersionedView()
        }
        let versionedViewRenderTime = measureRender(iterations: 100) {
            EngineVersionedView()
        }
        print("VersionedView: \(viewBuilderRenderTime) vs. \(versionedViewRenderTime)") // 0.65ms vs. 0.21ms
        XCTAssertGreaterThan(viewBuilderRenderTime, versionedViewRenderTime)

        // ForEach performance greatly depends on the child being a "Unary View". Since `VersionedView`
        // uses `_makeView` overrides, if used within a ForEach it should be within a "Unary" view
        // such as VStack/HStack/ZStack
        let viewBuilderForEachRenderTime = measureRender(iterations: 10) {
            ForEach(0..<1000, id: \.self) { _ in
                VStack {
                    ViewBuilderVersionedView()
                }
            }
        }
        let versionedViewForEachRenderTime = measureRender(iterations: 10) {
            ForEach(0..<1000, id: \.self) { _ in
                VStack {
                    EngineVersionedView()
                }
            }
        }
        print("VersionedView (ForEach): \(viewBuilderForEachRenderTime) vs. \(versionedViewForEachRenderTime)") // 258ms vs. 215ms
        XCTAssertGreaterThan(viewBuilderForEachRenderTime, versionedViewForEachRenderTime)
    }

    func testConditionalView() {
        struct DynamicConditionalContent: View {
            var flag: Bool
            var body: some View {
                if flag {
                    Text("Enabled")
                } else {
                    Text("Disabled")
                }
            }
        }
        struct StaticFlag: ViewInputFlag { }
        struct StaticConditionalContent: View {
            var body: some View {
                ViewInputConditionalContent(StaticFlag.self) {
                    Text("Enabled")
                } otherwise: {
                    Text("Disabled")
                }
            }
        }

        let dynamicRenderTime = measureRender(iterations: 100) {
            DynamicConditionalContent(flag: true)
        }
        let staticViewRenderTime = measureRender(iterations: 100) {
            StaticConditionalContent()
                .input(StaticFlag.self)
        }
        print("\(dynamicRenderTime) vs. \(staticViewRenderTime)") // 0.67ms vs. 0.24ms
        XCTAssertGreaterThan(dynamicRenderTime, staticViewRenderTime)
    }

    func testVariadicView() {
        struct MultiView: View {
            var body: some View {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
            }
        }

        let baseRenderTime = measureRender(iterations: 1_000) {
            VStack {
                MultiView()
            }
        }
        let transformedRenderTime = measureRender(iterations: 1_000) {
            VariadicViewAdapter {
                MultiView()
            } content: { subviews in
                VStack {
                    subviews
                }
            }
        }
        let percentCost = (transformedRenderTime - baseRenderTime) / baseRenderTime
        print("VariadicView: \(baseRenderTime) vs. \(transformedRenderTime) (\(Int(percentCost * 100))% Increase)") // 0.67ms vs. 0.82ms (20% Increase)
        XCTAssertLessThan(baseRenderTime, transformedRenderTime)
    }
}
