//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

private struct TestVisitor: MultiViewVisitor {
    var outputs: [(Any.Type, Context)] = []

    mutating func visit<Content: View>(content: Content, context: Context, stop: inout Bool) {
        outputs.append((Content.self, context))
    }
}

final class MultiViewVisitorTests: XCTestCase {

    fileprivate func expectation<Content: View>(
        @ViewBuilder content: () -> Content,
        visit: ([(type: Any.Type, context: TestVisitor.Context)]) -> Void
    ) {
        let content = content()
        var visitor = TestVisitor()
        content.visit(visitor: &visitor)
        visit(visitor.outputs)
    }

    func expectation<Element, Content: View>(
        _ type: Element.Type,
        @ViewBuilder content: () -> Content
    ) {
        expectation(content: content) { outputs in
            XCTAssertEqual(outputs.count, 1)
            XCTAssertEqual(
                unsafeBitCast(outputs[0].type, to: UnsafeRawPointer.self),
                unsafeBitCast(type, to: UnsafeRawPointer.self),
                "\(outputs[0].type) is not equal to \(type)"
            )
        }
    }

    func expectation<Content: View>(
        count: Int,
        @ViewBuilder content: () -> Content
    ) {
        expectation(content: content) { outputs in
            XCTAssertEqual(outputs.count, count)
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAnyView() {
        expectation(count: 1) {
            AnyView(Text("Hello, World"))
        }
        expectation(count: 2) {
            TupleView((Text("Hello"), Text("World")))
        }
    }

    func testGroup() {
        expectation(count: 1) {
            Group {
                Text("Hello, World")
            }
        }
        expectation(count: 2) {
            Group {
                Text("Hello")
                Text("World")
            }
        }
        expectation(count: 1) {
            Group {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        expectation(count: 2) {
            Group {
                Group {
                    Text("Hello")
                    Text("World")
                }
            }
        }
    }

    func testTupleView() {
        expectation(count: 1) {
            TupleView(Text("Hello, World"))
        }
        expectation(count: 2) {
            TupleView((EmptyView(), TupleView((Text("Hello"), Text("World")))))
        }
        expectation(count: 1) {
            VStack {
                TupleView((Text("Hello"), Text("World")))
            }
        }
    }

    func testEmptyView() {
        expectation(count: 0) {
            EmptyView()
        }
        expectation(count: 0) {
            EmptyView()
                .modifier(EmptyModifier())
        }
    }

    func testSection() {
        expectation(count: 3) {
            Section {
                Text("Content")
            } header: {
                Text("Header")
                Text("Subheader")
            } footer: {
                Text("Footer")
                Text("Subfooter")
            }
        }
        expectation(count: 4) {
            Section {
                Text("Hello")
                Text("World")
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
        }
    }

    func testForEach() {
        struct Item: Identifiable {
            var id: String
        }
        expectation(count: 3) {
            ForEach([Item(id: "one"), Item(id: "two"), Item(id: "three")]) { item in
                Text(item.id)
            }
        }
        expectation(count: 3) {
            ForEach(0...2, id: \.self) { index in
                Text(index.description)
            }
        }
        expectation(count: 4) {
            Text("Hello, World")
            ForEach(0...2, id: \.self) { index in
                Text(index.description)
            }
        }
        expectation(count: 9) {
            ForEach(0...2, id: \.self) { _ in
                ForEach(0...2, id: \.self) { index in
                    Text(index.description)
                }
            }
        }
    }

    func testOptional() {
        var flag = false
        expectation(count: 0) {
            if flag {
                Text("Hello, World")
            }
        }
        flag = true
        expectation(count: 1) {
            if flag {
                Text("Hello, World")
            }
        }
        expectation(count: 2) {
            if flag {
                Text("Hello")
                Text("World")
            }
        }
    }

    func testModifiedContent() {
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
            }
        }
        expectation(count: 1) {
            Text("Hello, World")
                .modifier(EmptyModifier())
        }
        expectation(count: 1) {
            Text("Hello, World")
                .modifier(MyModifier())
                .modifier(EmptyModifier())
        }
        expectation(count: 2) {
            Group {
                Text("Hello")
                Text("World")
            }
            .modifier(EmptyModifier())
        }
        expectation(count: 2) {
            Group {
                Text("Hello")
                Text("World")
            }
            .modifier(MyModifier())
            .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<Text, EmptyModifier>.self) {
            Text("Hello, World")
                .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<ModifiedContent<Text, MyModifier>, EmptyModifier>.self) {
            Text("Hello, World")
                .modifier(MyModifier())
                .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<ModifiedContent<Text, MyModifier>, EmptyModifier>.self) {
            Group {
                Text("Hello, World")
                    .modifier(MyModifier())
            }
            .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<Text, EmptyModifier>.self) {
            Group {
                Text("Hello, World")
            }
            .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<Text, EmptyModifier>.self) {
            ForEach(0..<1, id: \.self) { _ in
                Text("Hello, World")
            }
            .modifier(EmptyModifier())
        }
        expectation(ModifiedContent<Text, EmptyModifier>.self) {
            TupleView(Text("Hello, World"))
                .modifier(EmptyModifier())
        }
        expectation {
            Section {
                Text("Hello, World")
            } header: {
                Text("Header")
                    .modifier(EmptyModifier())
            } footer: {
                Text("Footer")
                    .modifier(EmptyModifier())
            }
        } visit: { outputs in
            XCTAssertEqual(outputs.count, 3)
            XCTAssert(outputs[0].context.traits.contains(.header))
            XCTAssertEqual(
                unsafeBitCast(outputs[0].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
            XCTAssert(outputs[1].context.traits.isEmpty)
            XCTAssert(outputs[2].context.traits.contains(.footer))
            XCTAssertEqual(
                unsafeBitCast(outputs[2].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
        }
    }

    func testCustomView() {
        struct CustomView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        struct CustomMultiView: View {
            var body: some View {
                Text("Hello")
                Text("World")
            }
        }
        expectation(count: 1) {
            CustomView()
        }
        expectation(count: 1) {
            Group {
                CustomView()
            }
        }
        expectation(count: 2) {
            CustomMultiView()
        }
        expectation(count: 2) {
            Group {
                CustomMultiView()
            }
        }
    }

    func testStop() {
        struct IsEmptyVisitor: MultiViewVisitor {
            var isEmpty = true

            mutating func visit<Content: View>(
                content: Content,
                context: Context,
                stop: inout Bool
            ) {
                XCTAssertTrue(isEmpty, "visit did not stop")
                isEmpty = false
                stop = true
            }
        }

        func expectation<Content: View>(
            isEmpty: Bool,
            @ViewBuilder content: () -> Content
        ) {
            let content = content()
            var visitor = IsEmptyVisitor()
            content.visit(visitor: &visitor)
            XCTAssertEqual(visitor.isEmpty, isEmpty)
        }

        expectation(isEmpty: true) {
            EmptyView()
        }

        expectation(isEmpty: true) {
            EmptyView()
                .padding()
        }

        expectation(isEmpty: false) {
            Text("Hello, World")
        }

        var flag = false
        expectation(isEmpty: true) {
            if flag {
                Text("Hello, World")
            }
        }

        flag = true
        expectation(isEmpty: false) {
            if flag {
                Text("Hello, World")
            }
        }

        expectation(isEmpty: true) {
            AnyView(EmptyView())
        }

        expectation(isEmpty: false) {
            AnyView(Text("Hello, World"))
        }

        expectation(isEmpty: false) {
            Text("Hello")
            Text("World")
        }

        expectation(isEmpty: false) {
            Group {
                Text("Hello")
                Text("World")
            }
        }

        expectation(isEmpty: false) {
            Section {
                Text("Hello, World")
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
        }

        expectation(isEmpty: false) {
            ForEach(0...2, id: \.self) { index in
                Text(index.description)
            }
        }

        struct CustomEmptyView: View {
            var body: some View {
                EmptyView()
            }
        }
        expectation(isEmpty: true) {
            CustomEmptyView()
        }

        struct CustomView: View {
            var body: some View {
                Text("Hello, World")
            }
        }
        expectation(isEmpty: false) {
            CustomView()
        }
    }
}
