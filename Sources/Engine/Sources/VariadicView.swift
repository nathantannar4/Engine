//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that transforms a `Source` view to `Content`
///
/// Most views such as `ZStack`, `VStack` and `HStack` are
/// unary views. This means they would produce a single subview
/// if transformed by a ``VariadicViewAdapter``. This is contrary
/// to `ForEach`, `TupleView`, `Section` and `Group` which
/// would produce multiple subviews. This different in behaviour can be
/// crucial, as it impacts: layout, how a view is modified by a `ViewModifier`,
/// and performance.
///
/// With ``VariadicViewAdapter`` an alias to the individual views can
/// be accessed along with any `_ViewTraitKey`,  the `.tag(...)`
/// value and `.id(...)`. This can be particularly useful when building
/// a custom picker, mapping a `Hashable` selection, or bridging to
/// UIKit/AppKit components.
///
@frozen
public struct VariadicViewAdapter<Source: View, Content: View>: View {

    @usableFromInline
    var source: Source

    @usableFromInline
    var content: (VariadicView) -> Content

    @inlinable
    public init(
        source: Source,
        content: @escaping (VariadicView) -> Content
    ) {
        self.source = source
        self.content = content
    }


    @inlinable
    public init(
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping (VariadicView) -> Content
    ) {
        self.init(source: source(), content: content)
    }

    public var body: some View {
        VariadicViewVisitor(
            source: source,
            layout: AnyVariadicViewLayout(content: content)
        )
    }
}

@frozen
public struct VariadicViewVisitor<
    Source: View,
    Layout: VariadicViewLayout
>: View {

    @usableFromInline
    var source: Source

    @usableFromInline
    var layout: Layout

    @inlinable
    public init(
        source: Source,
        layout: Layout
    ) {
        self.source = source
        self.layout = layout
    }

    @inlinable
    public init(
        layout: Layout,
        @ViewBuilder source: () -> Source,
    ) {
        self.init(source: source(), layout: layout)
    }

    public var body: some View {
        _VariadicView.Tree(Root(layout: layout)) {
            source
        }
    }

    private struct Root: _VariadicView.MultiViewRoot {
        var layout: Layout

        func body(children: _VariadicView.Children) -> some View {
            layout.body(children: VariadicView(children))
        }
    }
}

@MainActor @preconcurrency
public protocol VariadicViewLayout: DynamicProperty {

    associatedtype Body: View

    @ViewBuilder func body(children: VariadicView) -> Body
}

@frozen
public struct AnyVariadicViewLayout<
    Content: View
>: VariadicViewLayout {

    public var content: (VariadicView) -> Content

    public init(
        content: @escaping (VariadicView) -> Content
    ) {
        self.content = content
    }

    public func body(children: VariadicView) -> some View {
        content(children)
    }
}

@available(*, deprecated, renamed: "VariadicView")
public typealias AnyVariadicView = VariadicView

/// A type-erased collection of subviews in a container view.
@frozen
public struct VariadicView: View, RandomAccessCollection, Sequence {

    /// A type-erased subview of a container view.
    @frozen
    public struct Subview: View, Identifiable {

        @usableFromInline
        nonisolated(unsafe) var element: _VariadicView.Children.Element

        nonisolated init(_ element: _VariadicView.Children.Element) {
            self.element = element
        }

        @frozen
        public struct ID: Hashable, @unchecked Sendable {
            var value: AnyHashable
        }
        public nonisolated var id: ID {
            ID(value: element.id)
        }

        public func id<ID: Hashable>(as _: ID.Type = ID.self) -> ID? {
            element.id(as: ID.self)
        }

        @inlinable
        public func selection<ID: Hashable>(as _: ID.Type = ID.self) -> ID? {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *),
                let tag = tag(as: ID.self)
            {
                return tag
            } else if let id = id(as: ID.self) {
                return id
            }
            return nil
        }

        public subscript<K: _ViewTraitKey>(key: K.Type) -> K.Value {
            get { element[K.self] }
            set { element[K.self] = newValue }
        }

        public func trait<K: _ViewTraitKey>(
            _ key: K.Type
        ) -> K.Value? {
            self[K.self]
        }

        public subscript<K: ViewTraitKey>(
            key: K.Type,
            default defaultValue: @autoclosure () -> K.Value
        ) -> K.Value {
            self[K.self] ?? defaultValue()
        }

        public func trait<K: ViewTraitKey>(
            _ key: K.Type
        ) -> K.Value? {
            self[K.self]
        }

        public subscript<T>(key: String, as _: T.Type) -> T? {
            if let conformance = ViewTraitKeyProtocolDescriptor.conformance(of: key) {
                var visitor = AnyTraitVisitor<T>(element: element)
                conformance.visit(visitor: &visitor)
                return visitor.value
            }
            return nil
        }

        public func trait<T>(
            key: String,
            as _: T.Type
        ) -> T? {
            self[key, as: T.self]
        }

        private struct AnyTraitVisitor<T>: ViewTraitKeyVisitor {
            var element: _VariadicView.Children.Element
            var value: T!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                value = element[Key.self] as? T
            }
        }

        /// The tag value of the subview.
        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public func tag<T>(as _: T.Type) -> T? {
            let tag = self[TagValueTrait<T>.self, default: .untagged]
            switch tag {
            case .tagged(let value):
                return value
            case .untagged:
                return nil
            }
        }

        /// The z-index of the subview.
        public var zIndex: Double {
            self[ZIndexTrait.self, default: 0]
        }

        /// A flag indicating if the subview is a header
        public var isHeader: Bool {
            self[IsSectionHeaderTrait.self, default: false]
        }

        /// A flag indicating if the subview is a footer
        public var isFooter: Bool {
            self[IsSectionFooterTrait.self, default: false]
        }

        // MARK: View

        public var body: some View {
            element
        }
    }

    nonisolated(unsafe) var storage: _VariadicView.Children

    init(_ children: _VariadicView.Children) {
        self.storage = children
    }

    // MARK: View

    public var body: some View {
        storage
    }

    // MARK: Sections

    @available(*, deprecated, message: "Use `self` directly")
    public var children: VariadicView {
        return self
    }

    public var sections: [VariadicSectionView] {
        var sections: [VariadicSectionView] = [
            VariadicSectionView(id: 0)
        ]
        for element in self {
            if element.isHeader {
                if sections[sections.endIndex - 1].header.child != nil || !sections[sections.endIndex - 1].content.isEmpty {
                    sections.append(VariadicSectionView(id: sections.endIndex))
                }
                sections[sections.endIndex - 1].id = element.id
                sections[sections.endIndex - 1].header.child = element

            } else if element.isFooter {
                if sections[sections.endIndex - 1].footer.child != nil {
                    sections.append(VariadicSectionView(id: sections.endIndex))
                }
                sections[sections.endIndex - 1].footer.child = element

            } else {
                if sections[sections.endIndex - 1].footer.child != nil {
                    sections.append(VariadicSectionView(id: sections.endIndex))
                }
                if sections[sections.endIndex - 1].header.child == nil && sections[sections.endIndex - 1].content.isEmpty {
                    sections[sections.endIndex - 1].id = element.id
                }
                sections[sections.endIndex - 1].content.children.append(element)

            }
        }
        return sections
    }

    // MARK: Sequence

    public typealias Iterator = IndexingIterator<Array<Element>>

    public nonisolated func makeIterator() -> Iterator {
        storage.map { Subview($0) }.makeIterator()
    }

    public nonisolated var underestimatedCount: Int {
        storage.underestimatedCount
    }

    // MARK: RandomAccessCollection

    public typealias Element = Subview
    public typealias Index = Int

    public nonisolated var startIndex: Index {
        storage.startIndex
    }

    public nonisolated var endIndex: Index {
        storage.endIndex
    }

    public nonisolated subscript(position: Index) -> Element {
        Subview(storage[position])
    }

    public nonisolated func index(after index: Index) -> Index {
        storage.index(after: index)
    }
}

#if hasAttribute(retroactive)
extension Slice: @retroactive View where Element == VariadicView.Subview, Index: SignedInteger, Base.Index.Stride: SignedInteger {

    public var body: some View {
        let subviews = (startIndex..<endIndex).map { index in
            return base[index]
        }
        ForEachSubview(subviews) { _, subview in
            subview
        }
    }
}
#else
extension Slice: View where Element == VariadicView.Subview, Index: SignedInteger, Base.Index.Stride: SignedInteger {

    public var body: some View {
        let subviews = (startIndex..<endIndex).map { index in
            return base[index]
        }
        ForEachSubview(subviews) { _, subview in
            subview
        }
    }
}
#endif

@frozen
public struct VariadicSectionView: View, Identifiable {

    public typealias Header = Subview
    public typealias Footer = Subview

    @frozen
    public struct Subview: View {
        var child: VariadicView.Subview?

        public var body: some View {
            child
        }
    }

    @frozen
    public struct Content: View, RandomAccessCollection, Sequence {
        public typealias Subview = VariadicView.Subview
        var children: [Subview]

        public var body: some View {
            ForEachSubview(children) { _, subview in
                subview
            }
        }

        // MARK: Sequence

        public typealias Iterator = IndexingIterator<Array<Element>>

        public nonisolated func makeIterator() -> Iterator {
            children.makeIterator()
        }

        public nonisolated var underestimatedCount: Int {
            children.underestimatedCount
        }

        // MARK: RandomAccessCollection

        public typealias Element = Subview
        public typealias Index = Int

        public nonisolated var startIndex: Index {
            children.startIndex
        }

        public nonisolated var endIndex: Index {
            children.endIndex
        }

        public nonisolated subscript(position: Index) -> Element {
            children[position]
        }

        public nonisolated func index(after index: Index) -> Index {
            children.index(after: index)
        }
    }

    public nonisolated(unsafe) var id: AnyHashable
    public var header: Header
    public var content: Content
    public var footer: Footer

    init(
        id: AnyHashable,
        header: VariadicView.Subview? = nil,
        content: [VariadicView.Subview] = [],
        footer: VariadicView.Subview? = nil
    ) {
        self.id = id
        self.header = .init(child: header)
        self.content = .init(children: content)
        self.footer = .init(child: footer)
    }

    public var body: some View {
        Section {
            content
        } header: {
            header
        } footer: {
            footer
        }
    }
}

// MARK: - Previews

private struct PreviewTestEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = "default"
}

extension EnvironmentValues {
    fileprivate var previewTest: String {
        get { self[PreviewTestEnvironmentKey.self] }
        set { self[PreviewTestEnvironmentKey.self] = newValue }
    }
}

struct VariadicView_Previews: PreviewProvider {
    private enum PreviewCases: Int, Hashable, CaseIterable {
        case one = 1
        case two
        case three
    }

    private struct VariadicAlias: ViewAlias { }

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

                                Text(verbatim: "\(subview.id)")
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
                    Text("Line 1").tag("1")
                    Text("Line 2").tag("2")
                    Text("Line 3").tag("3")
                } content: { source in
                    VariadicViewAdapter {
                        ForEachSubview(source) { index, subview in
                            HStack {
                                Text(subview.selection(as: String.self) ?? "nil")

                                subview
                            }
                            .id(subview.selection(as: String.self))
                        }
                    } content: { transformedSource in
                        VStack {
                            ForEachSubview(transformedSource) { index, subview in
                                HStack {
                                    Text(subview.selection(as: String.self) ?? "nil")

                                    subview
                                }
                            }
                        }
                    }

                }
            }
            .previewDisplayName("ForEachSubview Transform")

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
                        Text(source.count.description)

                        VStack {
                            source
                        }
                    }
                }
            }
            .previewDisplayName("Group")

            ZStack {
                VariadicViewAdapter {
                    Section {
                        Text("Content")
                    } header: {
                        SectionHeader {
                            Text("Header")
                        }
                    } footer: {
                        SectionFooter {
                            Text("Footer")
                        }
                    }
                } content: { source in
                    ForEach(source.sections) { section in
                        VStack {
                            HStack {
                                Text("Header: ")
                                section.header
                            }
                            .border(Color.red)

                            section.content

                            HStack {
                                Text("Footer: ")
                                section.footer
                            }
                            .border(Color.red)
                        }
                    }
                }
            }
            .previewDisplayName("Section")

            ZStack {
                VariadicViewAdapter {
                    Section {
                        Text("Content 1")
                    } header: {
                        SectionHeader {
                            Text("Header 1")
                        }
                    } footer: {
                        SectionFooter {
                            Text("Footer 1")
                        }
                    }

                    Text("Content 2a")

                    Text("Content 2b")

                    Section {
                        Text("Content 3")
                    } header: {
                        SectionHeader {
                            Text("Header 3")
                        }
                    } footer: {
                        SectionFooter {
                            Text("Footer 3")
                        }
                    }

                    Section {
                        Text("Content 4")
                    }

                    Section {

                    } header: {
                        SectionHeader {
                            Text("Header 5")
                        }
                    }
                } content: { source in
                    VStack {
                        ForEach(source.sections) { section in
                            Section {
                                HStack {
                                    Text(verbatim: "\(section.id)")

                                    VStack {
                                        ForEach(section.content) { child in
                                            child
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(verbatim: "\(section.id)")

                                    section.header
                                }
                            } footer: {
                                HStack {
                                    Text(verbatim: "\(section.id)")

                                    section.footer
                                }
                            }

                            Divider()
                        }
                    }
                }
            }
            .previewDisplayName("Multi Section")

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")

                    Group {
                        Text("Line 2")
                        Text("Line 3")
                    }
                } content: { source in
                    HStack {
                        Text(source.count.description)

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
                    Text(source.count.description)
                }
            }
            .previewDisplayName("EmptyView")

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")
                } content: { source in
                    Text(source.count.description)
                }
            }
            .previewDisplayName("Text View")

            ZStack {
                VariadicViewAdapter {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                } content: { source in
                    let views = source[0...]
                    VStack {
                        HStack {
                            views[0]
                            views[1]
                        }

                        VStack {
                            views[2...]
                        }
                    }
                }
            }
            .previewDisplayName("Slice View")

            ZStack {
                VariadicViewAdapter {
                    VariadicAlias()
                } content: { source in
                    Text(source.count.description)
                }
                .viewAlias(VariadicAlias.self) {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                }
            }
            .previewDisplayName("ViewAlias")

            ZStack {
                StateAdapter(initialValue: 0) { $value in
                    VariadicViewAdapter {
                        Text("Label")
                    } content: { source in
                        Button {
                            value += 1
                        } label: {
                            HStack {
                                Text(value.description)

                                source
                            }
                        }
                    }
                }
            }
            .previewDisplayName("Styles")

            ZStack {
                VariadicViewAdapter {
                    Group {
                        EnvironmentValueReader(\.previewTest) { value in
                            Text(value)
                        }
                        .tag("Tag")
                        .id("ID")
                    }
                    // Fixes custom environment keys, but breaks reading tag/id
                    .modifier(UnaryViewModifier())

                    EnvironmentValueReader(\.previewTest) { value in
                        Text(value)
                    }
                    .tag("Tag")
                    .id("ID")
                } content: { source in
                    VStack {
                        ForEachSubview(source) { _, subview in
                            VStack {
                                subview
                                subview
                                    .font(.largeTitle)
                                HStack {
                                    EnvironmentValueReader(\.previewTest) { value in
                                        Text(value)
                                    }

                                    subview
                                }

                                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                                    let tag = subview.tag(as: String.self)
                                    Text(tag ?? "nil")

                                    let id = subview.id(as: String.self)
                                    Text(id ?? "nil")
                                }
                            }
                        }
                    }
                    .environment(\.previewTest, "Custom")
                }
            }
            .previewDisplayName("Environment")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
