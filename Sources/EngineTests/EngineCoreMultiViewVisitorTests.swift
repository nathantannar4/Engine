//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

final class MultiViewVisitorTests: XCTestCase {

    fileprivate func expectation<Content: View>(
        max: Int = .max,
        @ViewBuilder content: () -> Content,
        visit: ([(type: Any.Type, context: TestVisitor.Context)]) -> Void
    ) {
        let content = content()
        var visitor = TestVisitor(max: max)
        content.visit(visitor: &visitor)
        visit(visitor.outputs)
    }

    fileprivate func expectation<Element, Content: View>(
        _ type: Element.Type = Any.self,
        count: Int = 1,
        max: Int = .max,
        @ViewBuilder content: () -> Content,
        validation: (TestVisitor.Context, Int) -> Void = { _, _ in }
    ) {
        if count > 1, Content.Body.self == Never.self {
            func project<T>(_ type: T.Type) {
                XCTAssertNotNil(MultiViewProtocolDescriptor.conformance(of: type))
            }
            _openExistential(Content.self as Any.Type, do: project)
        }
        expectation(max: max, content: content) { outputs in
            XCTAssertEqual(outputs.count, count)
            for (index, output) in outputs.enumerated() {
                if type != Any.self {
                    XCTAssertEqual(
                        unsafeBitCast(output.type, to: UnsafeRawPointer.self),
                        unsafeBitCast(type, to: UnsafeRawPointer.self),
                        "\(output.type) is not equal to \(type)"
                    )
                }
                validation(output.context, index)
            }
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAnyView() {
        expectation(Text.self) {
            AnyView(Text("Hello, World"))
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(AnyView.self).appending(Text.self))
        }
        expectation(Text.self, count: 2) {
            AnyView(TupleView((Text("Hello"), Text("World"))))
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(AnyView.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
    }

    func testGroup() {
        expectation(Text.self) {
            Group {
                Text("Hello, World")
            }
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(Group<Text>.self).appending(Text.self))
        }
        expectation(Text.self, count: 2) {
            Group {
                Text("Hello")
                Text("World")
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(Group<TupleView<(Text, Text)>>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
        expectation(VStack<TupleView<(Text, Text)>>.self) {
            Group {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        expectation(Text.self, count: 2) {
            Group {
                Group {
                    Text("Hello")
                    Text("World")
                }
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(Group<Group<TupleView<(Text, Text)>>>.self).appending(Group<TupleView<(Text, Text)>>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
    }

    func testTupleView() {
        expectation(Text.self) {
            TupleView(Text("Hello, World"))
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(TupleView<Text>.self).appending(Text.self))
        }
        expectation(Text.self, count: 2) {
            TupleView((EmptyView(), TupleView((Text("Hello"), Text("World")))))
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(TupleView<(EmptyView, TupleView<(Text, Text)>)>.self).appending(offset: 1).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
        expectation(VStack<TupleView<(Text, Text)>>.self) {
            VStack {
                TupleView((Text("Hello"), Text("World")))
            }
        }
        expectation(count: 3) {
            Text("Line 1")
            Text("Line 2")
                .padding()
            VStack {
                Text("Line 3")
            }
        } validation: { ctx, index in
            let base = ViewTypeIdentifier(TupleView<(Text, ModifiedContent<Text, _PaddingLayout>, VStack<Text>)>.self).appending(offset: index)
            switch index {
            case 0:
                XCTAssertEqual(ctx.id, base.appending(Text.self))
            case 1:
                XCTAssertEqual(ctx.id, base.appending(ModifiedContent<Text, _PaddingLayout>.self))
            case 2:
                XCTAssertEqual(ctx.id, base.appending(VStack<Text>.self))
            default:
                XCTFail()
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
        expectation(count: 0) {
            EmptyView()
                .padding()
        }
        let flag = false
        expectation(count: 0) {
            if flag {
                Text("Hello, World")
            }
        }
        expectation(count: 0) {
            AnyView(EmptyView())
        }
        struct CustomEmptyView: View {
            var body: some View {
                EmptyView()
            }
        }
        expectation(count: 0) {
            CustomEmptyView()
        }
    }

    func testSection() {
        expectation(count: 3) {
            Section {
                Text("Content")
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(Section<Text, Text, Text>.self).appending(offset: index).appending(Text.self))
        }
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
        expectation(count: 3) {
            Section {
                Text("Content")
            } header: {
                Group {
                    Text("Header")
                    Text("Subheader")
                }
            } footer: {
                Group {
                    Text("Footer")
                    Text("Subfooter")
                }
            }
        }
        expectation(count: 3) {
            Section {
                Text("Content")
            } header: {
                ForEach(0...2, id: \.self) { i in
                    Text("Header \(i)")
                }
            } footer: {
                ForEach(0...2, id: \.self) { i in
                    Text("Footer \(i)")
                }
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
        expectation(count: 1) {
            Section {
                Text("Hello World")
            }
        }
        expectation(count: 0) {
            Section {
                EmptyView()
            }
        }
        struct CustomHeader: View {
            var body: some View {
                Group {
                    Text("Header")
                    Text("Subheader")
                }
            }
        }
        struct CustomFooter: View {
            var body: some View {
                Group {
                    Text("Footer")
                    Text("Subfooter")
                }
            }
        }
        expectation(count: 3) {
            Section {
                Text("Content")
            } header: {
                CustomHeader()
            } footer: {
                CustomFooter()
            }
        } validation: { ctx, index in
            let base = ViewTypeIdentifier(Section<CustomHeader, Text, CustomFooter>.self).appending(offset: index)
            switch index {
            case 0:
                XCTAssertEqual(ctx.id, base.appending(CustomHeader.self))
            case 1:
                XCTAssertEqual(ctx.id, base.appending(Text.self))
            case 2:
                XCTAssertEqual(ctx.id, base.appending(CustomFooter.self))
            default:
                XCTFail()
            }
        }
    }

    func testForEach() {
        struct Item: Identifiable {
            var id: String
            static var allItems: [Item] = [
                Item(id: "one"), Item(id: "two"), Item(id: "three")
            ]
        }
        expectation(Text.self, count: 3) {
            ForEach(Item.allItems) { item in
                Text(item.id)
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(ForEach<Array<Item>, String, Text>.self).appending(offset: Item.allItems[index].id).appending(Text.self))
        }
        expectation(Text.self, count: 3) {
            ForEach(0...2, id: \.self) { index in
                Text(index.description)
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(ForEach<ClosedRange<Int>, Int, Text>.self).appending(offset: index).appending(Text.self))
        }
        expectation(Text.self, count: 4) {
            Text("Hello, World")
            ForEach(0...2, id: \.self) { index in
                Text(index.description)
            }
        } validation: { ctx, index in
            let id = ViewTypeIdentifier(TupleView<(Text, ForEach<ClosedRange<Int>, Int, Text>)>.self).appending(offset: min(index, 1))
            switch index {
            case 0:
                XCTAssertEqual(ctx.id, id.appending(Text.self))
            default:
                XCTAssertEqual(ctx.id, id.appending(ForEach<ClosedRange<Int>, Int, Text>.self).appending(offset: index - 1).appending(Text.self))
            }
        }
        expectation(Text.self, count: 9) {
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
        expectation(Text.self) {
            if flag {
                Text("Hello, World")
            }
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(Optional<Text>.self).appending(Text.self))
        }
        expectation(Text.self, count: 2) {
            if flag {
                Text("Hello")
                Text("World")
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(Optional<TupleView<(Text, Text)>>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
    }

    func testAvailable() {
        expectation(Text.self) {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Text("Hello, World")
            }
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(Optional<AnyView>.self).appending(AnyView.self).appending(Text.self))
        }
    }

    func testConditionalContent() {
        var flag = false
        expectation(Text.self, count: 2) {
            if flag {
                Text("Hello, World")
            } else {
                Text("Hello")
                Text("World")
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(_ConditionalContent<Text, TupleView<(Text, Text)>>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
        flag = true
        expectation(Text.self) {
            if flag {
                Text("Hello, World")
            } else {
                Text("Hello")
                Text("World")
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(_ConditionalContent<Text, TupleView<(Text, Text)>>.self).appending(Text.self))
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
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(ModifiedContent<Text, EmptyModifier>.self))
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
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(ModifiedContent<Group<TupleView<(Text, Text)>>, EmptyModifier>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
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
        expectation(ModifiedContent<Text, EmptyModifier>.self, count: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Text("Hello, World")
            }
            .modifier(EmptyModifier())
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(ModifiedContent<ForEach<Range<Int>, Int, Text>, EmptyModifier>.self).appending(offset: index).appending(Text.self))
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
        expectation {
            Section {
                Text("Hello, World")
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
            .modifier(EmptyModifier())
        } visit: { outputs in
            XCTAssertEqual(outputs.count, 3)
            XCTAssert(outputs[0].context.traits.contains(.header))
            XCTAssertEqual(
                unsafeBitCast(outputs[0].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
            XCTAssert(outputs[1].context.traits.isEmpty)
            XCTAssertEqual(
                unsafeBitCast(outputs[1].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
            XCTAssert(outputs[2].context.traits.contains(.footer))
            XCTAssertEqual(
                unsafeBitCast(outputs[2].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
        }
        expectation {
            Section {
                Text("Hello, World")
                    .modifier(EmptyModifier())
            }
        } visit: { outputs in
            XCTAssertEqual(outputs.count, 1)
            XCTAssert(outputs[0].context.traits.isEmpty)
            XCTAssertEqual(
                unsafeBitCast(outputs[0].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
        }
        expectation {
            Section {
                Text("Hello, World")
                    .modifier(EmptyModifier())
            } header: {
                Group {
                    Text("Header")
                    Text("Subheader")
                }
                .modifier(EmptyModifier())
            } footer: {
                Group {
                    Text("Footer")
                    Text("Subfooter")
                }
                .modifier(EmptyModifier())
            }
        } visit: { outputs in
            XCTAssertEqual(outputs.count, 3)
            XCTAssert(outputs[0].context.traits.contains(.header))
            XCTAssertEqual(
                unsafeBitCast(outputs[0].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Group<TupleView<(Text, Text)>>, EmptyModifier>.self).metadata
            )
            XCTAssert(outputs[1].context.traits.isEmpty)
            XCTAssertEqual(
                unsafeBitCast(outputs[1].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Text, EmptyModifier>.self).metadata
            )
            XCTAssert(outputs[2].context.traits.contains(.footer))
            XCTAssertEqual(
                unsafeBitCast(outputs[2].type, to: UnsafeRawPointer.self),
                TypeIdentifier(ModifiedContent<Group<TupleView<(Text, Text)>>, EmptyModifier>.self).metadata
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
        expectation(CustomView.self) {
            CustomView()
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(CustomView.self))
        }
        expectation(CustomView.self) {
            Group {
                CustomView()
            }
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(Group<CustomView>.self).appending(CustomView.self))
        }
        expectation(Text.self, count: 2) {
            CustomMultiView()
        } validation: { ctx, index in
            if isOpaqueViewAnyView() {
                XCTAssertEqual(ctx.id, .init(CustomMultiView.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
            } else {
                XCTAssertEqual(ctx.id, .init(CustomMultiView.self).appending(offset: index).appending(Text.self))
            }
        }
        expectation(Text.self, count: 2) {
            Group {
                CustomMultiView()
            }
        } validation: { ctx, index in
            if isOpaqueViewAnyView() {
                XCTAssertEqual(ctx.id, .init(Group<CustomMultiView>.self).appending(CustomMultiView.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
            } else {
                XCTAssertEqual(ctx.id, .init(Group<CustomMultiView>.self).appending(CustomMultiView.self).appending(offset: index).appending(Text.self))
            }
        }
    }

    #if os(iOS) || os(macOS)
    func testRepresentable() {
        #if os(macOS)
        struct CustomRepresentable: NSViewRepresentable {
            func makeNSView(context: Context) -> NSView { NSView() }
            func updateNSView(_ nsView: NSView, context: Context) { }
        }
        #else
        struct CustomRepresentable: UIViewRepresentable {
            func makeUIView(context: Context) -> UIView { UIView() }
            func updateUIView(_ uiView: UIView, context: Context) { }
        }
        #endif
        expectation(CustomRepresentable.self) {
            CustomRepresentable()
        }
    }
    #endif

    func testPrimitiveView() {
        struct PrimitiveView: View {
            var body: Never { fatalError() }
        }
        struct PrimitiveMultiView<Content: View>: View, MultiView {
            @ViewBuilder var content: Content
            var body: Never { fatalError() }
            func makeSubviewIterator() -> some MultiViewIterator {
                content.makeSubviewIterator()
            }
        }
        expectation(PrimitiveView.self) {
            PrimitiveView()
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(PrimitiveView.self))
        }
        expectation(Text.self) {
            PrimitiveMultiView {
                Text("Hello, World")
            }
        } validation: { ctx, _ in
            XCTAssertEqual(ctx.id, .init(PrimitiveMultiView<Text>.self))
        }
        expectation(Text.self, count: 2) {
            PrimitiveMultiView {
                Group {
                    Text("Hello")
                    Text("World")
                }
            }
        } validation: { ctx, index in
            XCTAssertEqual(ctx.id, .init(PrimitiveMultiView<Group<TupleView<(Text, Text)>>>.self).appending(TupleView<(Text, Text)>.self).appending(offset: index).appending(Text.self))
        }
    }

    func testStop() {
        expectation(count: 1, max: 1) {
            Text("Hello, World")
        }
        expectation(count: 1, max: 1) {
            Text("Line 1")
            Text("Line 2")
        }
        expectation(count: 1, max: 1) {
            Group {
                Text("Line 1")
                Text("Line 2")
            }
        }
    }
}

private struct TestVisitor: MultiViewVisitor {
    var outputs: [(Any.Type, Context)] = []
    var max: Int = .max

    mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        outputs.append((Content.self, context))
        stop = outputs.count >= max
    }
}
