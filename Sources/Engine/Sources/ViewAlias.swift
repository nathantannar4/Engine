//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is an alias for another view that's statically defined by an ancestor.
///
/// A ``ViewAlias`` is can be defined statically by one of its ancestors.
/// Because ``ViewAlias`` is guaranteed to be static it can be used for
/// type-erasure without the performance impacts associated with `AnyView`.
/// Use the ``View/viewAlias(_:source:)`` on an ancestor to define
/// the view ``ViewAlias`` should be resolved to.
///
/// For example, ``ViewAlias`` can be used for "dependency-injection".
/// Such as the case when creating a ``ViewStyle``.
///
///     struct RowConfiguration {
///         var label: LocalizedStringKey
///
///         struct Content: ViewAlias { }
///         var content: Content { .init() }
///     }
///
///     struct RowView: View {
///         var configuration: RowConfiguration
///
///         var body: some View {
///             HStack {
///                 Text(configuration.label)
///
///                 configuration.content
///             }
///         }
///     }
///
///     var body: some View {
///         RowView(configuration: .init(label: "Label"))
///             .viewAlias(RowConfiguration.Content.self) {
///                 Text("Content")
///             }
///     }
///
/// If a ``ViewAlias`` is not defined by one of its ancestors, its `body`
/// will be resolved to an `EmptyView`. If you would like a different fallback,
/// you can implement the optional `defaultBody`.
///
@MainActor @preconcurrency
public protocol ViewAlias: PrimitiveView where Body == Never {
    associatedtype DefaultBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var defaultBody: DefaultBody { get }
}

/// Statically type-erases a view to be resolved by the ``ViewAlias``.
@frozen
public struct ViewAliasSourceModifier<
    Alias: ViewAlias,
    Source: View
>: ViewModifier {

    @usableFromInline
    var source: Source

    @inlinable
    public init(
        _ : Alias.Type = Alias.self,
        source: Source
    ) {
        self.source = source
    }

    public func body(content: Content) -> some View {
        content.modifier(Modifier(source: source))
    }

    private struct Modifier: GraphInputsModifier {
        var source: Source

        public static func makeInputs(
            modifier: _GraphValue<Self>,
            inputs: inout _GraphInputs
        ) {
            if Alias.self != Source.self {
                inputs[ViewAliasInput<Alias>.self].append(
                    .init(
                        attribute: unsafeBitCast(modifier[\.source], to: _GraphValue<Any>.self),
                        type: Source.self
                    )
                )
            }
        }
    }
}

extension View {

    /// Statically type-erases `Source` to be resolved by the ``ViewAlias``.
    @inlinable
    public func viewAlias<
        Alias: ViewAlias,
        Source: View
    >(
        _ : Alias.Type,
        @ViewBuilder source: () -> Source
    ) -> some View {
        modifier(
            ViewAliasSourceModifier(
                Alias.self,
                source: source()
            )
        )
    }
}

private struct ViewAliasInput<ID: ViewAlias>: ViewInputKey {
    struct Element {
        var attribute: _GraphValue<Any>
        var type: Any.Type
    }

    typealias Value = [Element]
    static var defaultValue: [Element] { [] }
}

extension ViewAlias where DefaultBody == EmptyView {
    public var defaultBody: EmptyView {
        EmptyView()
    }
}

extension ViewAlias {
    public var body: Never {
        bodyError()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        var inputs = inputs
        guard let input = inputs[ViewAliasInput<Self>.self].popLast() else {
            return DefaultBody._makeView(view: view[\.defaultBody], inputs: inputs)
        }
        func project<T>(_ type: T.Type) -> _ViewOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewOutputsVisitor(view: input.attribute, inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(input.type, do: project)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        var inputs = inputs
        guard let input = inputs[ViewAliasInput<Self>.self].popLast() else {
            return DefaultBody._makeViewList(view: view[\.defaultBody], inputs: inputs)
        }
        func project<T>(_ type: T.Type) -> _ViewListOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsVisitor(view: input.attribute, inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(input.type, do: project)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        var inputs = inputs
        guard let input = inputs[ViewAliasInput<Self>.self].popLast() else {
            return DefaultBody._viewListCount(inputs: inputs)
        }
        func project<T>(_ type: T.Type) -> Int? {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsCountVisitor(inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(input.type, do: project)
    }
}

private struct ViewAliasBody<Content: View>: View {
    var body: Content
}

private struct ViewOutputsVisitor: ViewVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewInputs

    var outputs: _ViewOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(view, to: _GraphValue<ViewAliasBody<Content>>.self)
        outputs = ViewAliasBody<Content>._makeView(view: view, inputs: inputs)
    }
}

private struct ViewListOutputsVisitor: ViewVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewListInputs

    var outputs: _ViewListOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(view, to: _GraphValue<ViewAliasBody<Content>>.self)
        outputs = ViewAliasBody<Content>._makeViewList(view: view, inputs: inputs)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewListOutputsCountVisitor: ViewVisitor {
    var inputs: _ViewListCountInputs

    var outputs: Int?

    mutating func visit<Content>(type: Content.Type) where Content: View {
        outputs = ViewAliasBody<Content>._viewListCount(inputs: inputs)
    }
}

// MARK: - Previews

struct ViewAlias_Previews: PreviewProvider {
    struct PreviewAlias: ViewAlias {
        var defaultBody: some View {
            Text("Default")
        }
    }

    static var previews: some View {
        Group {
            ZStack {
                VStack {
                    PreviewAlias()

                    PreviewAlias()
                }
                .viewAlias(PreviewAlias.self) {
                    Text("Hello, World")
                }
            }
            .previewDisplayName("Text")

            ZStack {
                VStack {
                    PreviewAlias()
                }
                .viewAlias(PreviewAlias.self) {
                    ForEach(0...2, id: \.self) { index in
                        Text(index.description)
                    }
                }
            }
            .previewDisplayName("ForEach")

            ZStack {
                PreviewAlias()
            }
            .previewDisplayName("DefaultBody")
        }
    }
}
