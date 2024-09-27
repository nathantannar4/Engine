//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

final class ViewVisitorTests: XCTestCase {

    func testVisit() {
        let content = Text("Hello, World")
        var visitor = TestVisitor<Text>()
        content.visit(visitor: &visitor)
        XCTAssert(visitor.output)
    }

    func testOpaqueVisit() throws {
        func makeContent() -> some View {
            Text("Hello, World")
        }
        let content = makeContent()
        if isOpaqueViewAnyView() {
            var visitor = TestVisitor<AnyView>()
            content.visit(visitor: &visitor)
            XCTAssert(visitor.output)
        } else {
            var visitor = TestVisitor<Text>()
            content.visit(visitor: &visitor)
            XCTAssert(visitor.output)
        }
    }

    func testAnyVisit() throws {
        func makeContent() -> Any {
            Text("Hello, World")
        }
        let content = makeContent()
        var visitor = TestVisitor<Text>()
        func project<T>(_ content: T) throws {
            let conformance = try XCTUnwrap(ViewProtocolDescriptor.conformance(of: T.self))
            conformance.visit(visitor: &visitor)
        }
        try _openExistential(content, do: project)
        XCTAssert(visitor.output)
    }

    func testAnyViewVisit() {
        let content = AnyView(Text("Hello, World"))
        var visitor = TestVisitor<AnyView>()
        content.visit(visitor: &visitor)
        XCTAssert(visitor.output)
    }

    func testOptionalVisit() {
        let content = Optional.some(Text("Hello, World"))
        var visitor = TestVisitor<Optional<Text>>()
        content.visit(visitor: &visitor)
        XCTAssert(visitor.output)
    }

    #if os(iOS) || os(tvOS) || os(macOS)
    func testViewRepresentableVisit() {
        #if os(iOS) || os(tvOS)
        struct ViewRepresentable: UIViewRepresentable {
            func makeUIView(context: Context) -> UIView { UIView() }
            func updateUIView(_ uiView: UIView, context: Context) { }
        }
        #elseif os(macOS)
        struct ViewRepresentable: NSViewRepresentable {
            func makeNSView(context: Context) -> NSView { NSView() }
            func updateNSView(_ nsView: NSView, context: Context) { }
        }
        #endif
        let content = ViewRepresentable()
        var visitorA = TestRepresentableVisitor<ViewRepresentable>()
        content.visit(visitor: &visitorA)
        XCTAssert(visitorA.output)

        var visitorB = TestVisitor<ViewRepresentable>()
        content.visit(visitor: &visitorB)
        XCTAssert(visitorB.output)
    }
    #endif
}

private struct TestVisitor<ExpectedContent: View>: ViewVisitor {
    var output: Bool!

    mutating func visit<Content: View>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }
}

private struct TestRepresentableVisitor<ExpectedContent: View>: ViewVisitor {
    var output: Bool!

    mutating func visit<Content: View>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }

    #if os(iOS) || os(tvOS)
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: UIViewRepresentable>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }

    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: UIViewControllerRepresentable>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }
    #endif

    #if os(macOS)
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: NSViewRepresentable>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }

    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: NSViewControllerRepresentable>(type: Content.Type) {
        XCTAssertNil(output)
        output = ExpectedContent.self == Content.self
    }
    #endif
}
