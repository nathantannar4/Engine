//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A key that defines a list of `View`'s that are defined by descendants.
///
/// A ``ViewOutputKey`` can be optimized to be static rather than
/// type-erasure with `AnyView` by defining the `Content`.
///
/// Use the ``View/viewOutput(_:source:)`` on a descendant to
/// add the view to the output.
///
/// A ``ViewOutputKey`` value can be read by a ``ViewOutputKeyReader``.
/// 
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol ViewOutputKey {
    associatedtype Content: View = AnyView
    typealias Value = ViewOutputList<Content>
    static func reduce(value: inout Value, nextValue: () -> Value)
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ViewOutputKey where Value == ViewOutputList<Content> {
    public static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value.elements += nextValue().elements
    }
}

/// A list of views sourced by a ``ViewOutputKey``
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputList<Content: View>: View, RandomAccessCollection, Sequence {

    @frozen
    public struct Subview: View, Identifiable {

        public struct ID: Hashable {
            var value: Namespace.ID
        }

        public var id: ID
        public var content: Content

        var phase: UpdatePhase.Value

        init(
            id: Namespace.ID,
            phase: UpdatePhase.Value,
            content: Content
        ) {
            self.id = ID(value: id)
            self.phase = phase
            self.content = content
        }

        public var body: some View {
            content
        }
    }

    public var elements: [Subview]

    public var body: some View {
        ForEach(elements, id: \.id) { child in
            child
        }
    }

    // MARK: Sequence

    public typealias Iterator = IndexingIterator<Array<Element>>

    public func makeIterator() -> Iterator {
        elements.makeIterator()
    }

    public var underestimatedCount: Int {
        elements.underestimatedCount
    }

    // MARK: RandomAccessCollection

    public typealias Element = Subview
    public typealias Index = Int

    public var startIndex: Index {
        elements.startIndex
    }

    public var endIndex: Index {
        elements.endIndex
    }

    public subscript(position: Index) -> Element {
        elements[position]
    }

    public func index(after index: Index) -> Index {
        elements.index(after: index)
    }
}

/// A modifier that writes a `Source` view to a ``ViewOutputKey``
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputSourceModifier<
    Key: ViewOutputKey,
    Source: View
>: ViewModifier where Key.Content == Source {

    @usableFromInline
    var source: Source

    @Namespace var namespace
    @UpdatePhase var phase

    @inlinable
    public init(
        _ key: Key.Type = Key.self,
        source: Source
    ) {
        self.source = source
    }

    public func body(content: Content) -> some View {
        content
            .transformPreference(ViewOutputPreferenceKey<Key>.self) { value in
                ViewOutputPreferenceKey<Key>.reduce(value: &value) {
                    ViewOutputPreferenceKey<Key>.Value(
                        list: ViewOutputList<Key.Content>(
                            elements: [
                                ViewOutputList<Key.Content>.Element(
                                    id: namespace,
                                    phase: phase,
                                    content: source
                                )
                            ]
                        )
                    )
                }
            }
    }
}

extension View {

    /// A modifier that writes a `Source` view to a ``ViewOutputKey``
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public func viewOutput<
        Key: ViewOutputKey,
        Source: View
    >(
        _ : Key.Type,
        @ViewBuilder source: () -> Source
    ) -> some View where Key.Content == Source {
        modifier(
            ViewOutputSourceModifier(
                Key.self,
                source: source()
            )
        )
    }

    /// A modifier that writes a `Source` view to a ``ViewOutputKey``
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public func viewOutput<
        Key: ViewOutputKey,
        Source: View
    >(
        _ : Key.Type,
        @ViewBuilder source: () -> Source
    ) -> some View where Key.Content == AnyView {
        modifier(
            ViewOutputSourceModifier(
                Key.self,
                source: AnyView(source())
            )
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewOutputPreferenceKey<
    Key: ViewOutputKey
>: PreferenceKey {

    struct Value: Equatable {
        var list = ViewOutputList<Key.Content>(elements: [])

        public static func == (lhs: Value, rhs: Value) -> Bool {
            guard lhs.list.count == rhs.list.count else {
                return false
            }
            for (lhs, rhs) in zip(lhs.list, rhs.list) {
                if lhs.id != rhs.id || lhs.phase != rhs.phase {
                    return false
                }
            }
            return true
        }

    }

    static var defaultValue: Value { .init() }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        Key.reduce(
            value: &value.list,
            nextValue: { nextValue().list }
        )
    }
}

/// A proxy to a ``ViewOutputKey.Value`` that must be read by ``ViewOutputKeyValueReader``
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputKeyValueProxy<Key: ViewOutputKey> {
    fileprivate var value: PreferenceKeyValueProxy<ViewOutputPreferenceKey<Key>>
}

/// A container view that resolves it's content from a ``ViewOutputKey``
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputKeyReader<
    Key: ViewOutputKey,
    Content: View
>: View {

    public typealias Value = ViewOutputKeyValueProxy<Key>

    @usableFromInline
    var content: (Value) -> Content

    @inlinable
    public init(
        _ key: Key.Type,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.content = content
    }

    public var body: some View {
        PreferenceKeyReader(ViewOutputPreferenceKey<Key>.self) { value in
            content(Value(value: value))
        }
        .preference(key: ViewOutputPreferenceKey<Key>.self, value: .init())
    }
}

/// A container view that resolves it's content from a ``ViewOutputKey`` value
///
/// > Important: The ``ViewOutputKey`` value of `Content` is ignored
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputKeyValueReader<
    Key: ViewOutputKey,
    Content: View
>: View {

    @usableFromInline
    var value: ViewOutputKeyValueProxy<Key>

    @usableFromInline
    var content: (ViewOutputList<Key.Content>) -> Content

    @inlinable
    public init(
        _ value: ViewOutputKeyValueProxy<Key>,
        @ViewBuilder content: @escaping (ViewOutputList<Key.Content>) -> Content
    ) {
        self.value = value
        self.content = content
    }

    public var body: some View {
        PreferenceKeyValueReader(value.value) { view in
            content(view.list)
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ViewOutputKey_Previews: PreviewProvider {
    struct PreviewViewOutputKey: ViewOutputKey { }

    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var counter = 0

        var body: some View {
            ViewOutputKeyReader(PreviewViewOutputKey.self) { value in
                VStack {
                    VStack {
                        ViewOutputKeyValueReader(value) { views in
                            ForEach(views) { view in
                                view
                            }
                        }
                    }

                    ViewOutputKeyReader(PreviewViewOutputKey.self) { value in
                        VStack {
                            ViewOutputKeyValueReader(value) { views in
                                ForEach(views) { view in
                                    view
                                }
                            }
                        }
                        .viewOutput(PreviewViewOutputKey.self) {
                            Text("Hello, World")
                        }
                        .viewOutput(PreviewViewOutputKey.self) {
                            Button {
                                counter += 1
                            } label: {
                                Text(counter.description)
                            }
                        }
                    }
                }
            }
        }
    }
}
