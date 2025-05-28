//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is an alias for another view that's defined by a descendent.
///
/// A ``ViewOutputAlias`` can be optimized to be static rather than
/// type-erasure with `AnyView` by defining the `Content`.
///
/// Use the ``View/viewOutputAlias(_:source:)`` on a descendant to
/// define the source of the alias.
///
/// A ``ViewOutputAlias`` must be used within a ``ViewOutputAliasReader``.
/// If used outside the scope of a ``ViewOutputAliasReader`` or if the alias source
/// is not defined, its `body` will be resolved to an `EmptyView`. If you would like a
/// different fallback, you can implement the optional `defaultBody`.
///
/// See Also:
///  - ``ViewOutputKey``
///  - ``ViewAlias``
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol ViewOutputAlias: PrimitiveView {
    associatedtype Content: View = AnyView
    associatedtype DefaultBody: View = EmptyView
    @MainActor @ViewBuilder var defaultBody: DefaultBody { get }
}

/// A modifier that defines a `Source` view to a ``ViewOutputAlias``
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputAliasSourceModifier<
    Alias: ViewOutputAlias,
    Source: View
>: ViewModifier where Source == Alias.Content {

    @usableFromInline
    var source: Source

    @inlinable
    public init(
        _ key: Alias.Type = Alias.self,
        source: Source
    ) {
        self.source = source
    }

    public func body(content: Content) -> some View {
        content
            .viewOutput(ViewOutputAliasKey<Alias>.self) {
                source
            }
    }
}

extension View {

    /// Statically defines the `Source` to be resolved by the ``ViewOutputAlias``.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public func viewOutputAlias<
        Alias: ViewOutputAlias,
        Source: View
    >(
        _ : Alias.Type,
        @ViewBuilder source: () -> Source
    ) -> some View where Alias.Content == Source {
        modifier(
            ViewOutputAliasSourceModifier(
                Alias.self,
                source: source()
            )
        )
    }

    /// Defines a type-erased `Source` to be resolved by the ``ViewOutputAlias``.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public func viewOutputAlias<
        Alias: ViewOutputAlias,
        Source: View
    >(
        _ : Alias.Type,
        @ViewBuilder source: () -> Source
    ) -> some View where Alias.Content == AnyView {
        modifier(
            ViewOutputAliasSourceModifier(
                Alias.self,
                source: AnyView(source())
            )
        )
    }
}

/// A container view that defines the scope of a ``ViewOutputAlias``.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ViewOutputAliasReader<
    Alias: ViewOutputAlias,
    Content: View
>: View {

    @usableFromInline
    var content: Content

    @inlinable
    public init(
        _ alias: Alias.Type,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public var body: some View {
        ViewOutputKeyReader(ViewOutputAliasKey<Alias>.self) { value in
            content
                .viewAlias(ViewOutputAliasKey<Alias>.self) {
                    ViewOutputKeyValueReader(value) { view in
                        view
                    }
                }
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ViewOutputAlias where DefaultBody == EmptyView {
    public var defaultBody: EmptyView {
        EmptyView()
    }
}


@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ViewOutputAlias {

    private var content: ViewOutputAliasKey<Self> {
        ViewOutputAliasKey(alias: self)
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        ViewOutputAliasKey<Self>._makeView(
            view: view[\.content],
            inputs: inputs
        )
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        ViewOutputAliasKey<Self>._makeViewList(
            view: view[\.content],
            inputs: inputs
        )
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        ViewOutputAliasKey<Self>._viewListCount(
            inputs: inputs
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewOutputAliasKey<
    Alias: ViewOutputAlias
>: ViewOutputKey, ViewAlias {

    var alias: Alias

    var defaultBody: Alias.DefaultBody {
        alias.defaultBody
    }

    typealias Content = Alias.Content

    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value = nextValue()
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ViewOutputAlias_Previews: PreviewProvider {
    struct PreviewViewOutputAlias: ViewOutputAlias {
        var defaultBody: some View {
            Text("default")
        }
    }

    static var previews: some View {
        VStack {
            PreviewViewOutputAlias()

            ViewOutputAliasReader(PreviewViewOutputAlias.self) {
                VStack {
                    PreviewViewOutputAlias()

                    ViewOutputAliasReader(PreviewViewOutputAlias.self) {
                        VStack {
                            PreviewViewOutputAlias()
                        }
                        .viewOutputAlias(PreviewViewOutputAlias.self) {
                            Text("Hello, World A")
                        }
                        .viewOutputAlias(PreviewViewOutputAlias.self) {
                            Text("Hello, World B")
                        }
                    }
                }
            }
        }
    }
}
