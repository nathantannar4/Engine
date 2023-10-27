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

        public subscript<K: _ViewTraitKey>(key: K.Type) -> K.Value {
            get { element[K.self] }
            set { element[K.self] = newValue }
        }

        public subscript<T>(key: String, as _: T.Type) -> T? {
            if let conformance = ViewTraitKeyProtocolDescriptor.conformance(of: key) {
                var visitor = AnyTraitVisitor<T>(element: element)
                conformance.visit(visitor: &visitor)
                return visitor.value
            }
            return nil
        }

        private struct AnyTraitVisitor<T>: ViewTraitKeyVisitor {
            var element: _VariadicView.Children.Element
            var value: T!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                value = element[Key.self] as? T
            }
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public func tag<T>(as _: T.Type) -> T? {
            if let typeName = _mangledTypeName(T.self),
                let conformance = ViewTraitKeyProtocolDescriptor.conformance(
                of: "s7SwiftUI16TagValueTraitKeyVy\(typeName)G"
            ) {
                var visitor = TagTraitVisitor<T>(element: element)
                conformance.visit(visitor: &visitor)
                return visitor.tag
            }
            return nil
        }

        private struct TagTraitVisitor<T>: ViewTraitKeyVisitor {

            var element: _VariadicView.Children.Element
            var tag: T!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                let value = unsafeBitCast(element[Key.self], to: Optional<T>.self)
                tag = value
            }
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
        @ViewBuilder _ subview: @escaping (Int, AnyVariadicView.Subview) -> Subview
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
    public init(
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping (VariadicView<Source>) -> Content
    ) {
        self.source = source()
        self.content = content
    }

    public var body: some View {
        _VariadicView.Tree(Root(content: content)) {
            source
        }
    }

    private struct Root: _VariadicView.MultiViewRoot {
        var content: (VariadicView<Source>) -> Content

        func body(children: _VariadicView.Children) -> some View {
            content(VariadicView(children))
        }
    }
}

// MARK: - Previews

struct VariadicView_Previews: PreviewProvider {
    enum PreviewCases: Int, Hashable, CaseIterable {
        case one
        case two
        case three
    }

    static var previews: some View {
        Group {
            ZStack {
                VariadicViewAdapter {
                    Text("Line 1").id("1")
                    Text("Line 2").id("2")
                } content: { source in
                    VStack {
                        ForEachSubview(source) { index, subview in
                            Text(subview.id(as: String.self) ?? "nil")
                        }
                    }
                }
            }
            .previewDisplayName("Custom ID")

            ZStack {
                VariadicViewAdapter {
                    ForEach(PreviewCases.allCases, id: \.self) {
                        Text($0.rawValue.description)
                    }
                } content: { source in
                    VStack {
                        ForEachSubview(source) { index, subview in
                            HStack {
                                Text("\(subview.id(as: PreviewCases.self)?.rawValue ?? -1)")

                                Text(String("\(subview.id)"))
                            }
                            .background(index.isMultiple(of: 2) ? Color.red : Color.blue)
                        }
                    }
                }
            }
            .previewDisplayName("ForEach")

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                ZStack {
                    VariadicViewAdapter {
                        Text("Line 1").tag("1")
                        Text("Line 2").tag("2")
                    } content: { source in
                        VStack {
                            ForEachSubview(source) { index, subview in
                                Text(subview.tag(as: String.self) ?? "nil")
                            }
                        }
                    }
                }
                .previewDisplayName("Custom Tag")
            }

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")
                    Text("Line 2")
                } content: { source in
                    VStack {
                        source
                    }
                }
            }
            .previewDisplayName("TupleView")

            ZStack {
                VariadicViewAdapter {
                    Group {
                        Text("Line 1")
                        Text("Line 2")
                    }
                } content: { source in
                    HStack {
                        Text(source.children.count.description)

                        VStack {
                            source
                        }
                    }
                }
            }
            .previewDisplayName("Group")

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")

                    Group {
                        Text("Line 2")
                        Text("Line 3")
                    }
                } content: { source in
                    HStack {
                        Text(source.children.count.description)

                        VStack {
                            source
                        }
                    }
                }
            }
            .previewDisplayName("TupleView + Group")

            ZStack {
                VariadicViewAdapter {
                    EmptyView()
                } content: { source in
                    Text(source.children.count.description)
                }
            }
            .previewDisplayName("EmptyView")

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")
                } content: { source in
                    Text(source.children.count.description)
                }
            }
            .previewDisplayName("Text View")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
