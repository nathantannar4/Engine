//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A type-erased collection of subviews in a container view.
@frozen
public struct AnyVariadicView: View, RandomAccessCollection {

    /// A type-erased subview of a container view.
    @frozen
    public struct Subview: View, Identifiable {

        @usableFromInline
        var element: _VariadicView.Children.Element

        init(_ element: _VariadicView.Children.Element) {
            self.element = element
        }

        public var id: AnyHashable {
            element.id
        }

        public func id<ID: Hashable>(as _: ID.Type = ID.self) -> ID? {
            element.id(as: ID.self)
        }

        // MARK: View

        public var body: some View {
            element
        }
    }

    var children: _VariadicView.Children

    init(_ children: _VariadicView.Children) {
        self.children = children
    }

    // MARK: View

    public var body: some View {
        children
    }

    // MARK: Collection

    public typealias Element = Subview
    public typealias Iterator = IndexingIterator<Array<Element>>
    public typealias Index = Int

    public func makeIterator() -> Iterator {
        children.map { Subview($0) }.makeIterator()
    }

    public var startIndex: Index {
        children.startIndex
    }

    public var endIndex: Index {
        children.endIndex
    }

    public subscript(position: Index) -> Element {
        Subview(children[position])
    }

    public func index(after index: Index) -> Index {
        children.index(after: index)
    }
}

/// A view that transforms a each variadic view subview
@frozen
public struct ForEachSubview<
    Content: View,
    Subview: View
>: View {

    @usableFromInline
    var content: VariadicView<Content>

    @usableFromInline
    var subview: (Int, AnyVariadicView.Subview) -> Subview

    public init(
        _ content: VariadicView<Content>,
        _ subview: @escaping (Int, AnyVariadicView.Subview) -> Subview
    ) {
        self.content = content
        self.subview = subview
    }

    public var body: some View {
        ForEach(Array(content.children.enumerated()), id: \.element.id) { (index, element) in
            subview(index, element)
        }
    }
}

/// A container view with type-erased subviews
///
/// A variadic view impacts layout and how a `ViewModifier` is applied,
/// which can have a direct impact on performance.
@frozen
public struct VariadicView<Content: View>: View {

    public var children: AnyVariadicView

    init(_ children: _VariadicView.Children) {
        self.children = AnyVariadicView(children)
    }

    public var body: some View {
        children
    }
}

/// A view that transforms a view into a variadic view
@frozen
public struct VariadicViewAdapter<Source: View, Content: View>: View {

    @usableFromInline
    var source: Source

    @usableFromInline
    var content: (VariadicView<Source>) -> Content

    @inlinable
    public init(@ViewBuilder content: @escaping (VariadicView<Source>) -> Content, @ViewBuilder source: () -> Source) {
        self.source = source()
        self.content = content
    }

    public var body: some View {
        _VariadicView.Tree(Root(content: content)) {
            source
        }
    }

    private struct Root: _VariadicView.UnaryViewRoot {
        var content: (VariadicView<Source>) -> Content

        func body(children: _VariadicView.Children) -> some View {
            content(VariadicView(children))
        }
    }
}

// MARK: - Previews

struct VariadicView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VariadicViewAdapter { content in
                content
            } source: {
                Text("Line 1")
                Text("Line 2")
            }

            VariadicViewAdapter { content in
                Text(content.children.count.description)
            } source: {
                EmptyView()
            }

            VariadicViewAdapter { content in
                Text(content.children.count.description)
            } source: {
                Text("Line 1")
            }

            VariadicViewAdapter { content in
                Text(content.children.count.description)
            } source: {
                Text("Line 1")
                Text("Line 2")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
