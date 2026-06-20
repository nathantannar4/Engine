//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A macro that adds the necessary components of a ``StyledView``
///
/// A ``StyledView`` is an easier way to adopt the ``ViewStyle`` API
/// to transform a `View` into one that can be styled. The `body` of a
/// ``StyledView`` will become the default style if no other styled is applied.
///
/// ```
/// @StyledView
/// struct LabeledView<Label: View, Content: View>: StyledView {
///     var label: Label
///     var content: Content
///
///     var body: some View {
///         HStack {
///             label
///
///             content
///         }
///     }
/// }
///
/// extension View {
///     func labelViewStyle<Style: LabelViewStyle>(_ style: Style) -> some View {
///         modifier(LabelViewStyleModifier(style))
///     }
/// }
/// ```
///
/// Now imagine you need a "vertical" style that uses a `VStack` rather than an `HStack`.
/// With a custom style you can achieve this in a performant and type safe way.
/// Custom styles have access to all properties of the original ``StyledView``.
///
///     struct VerticalLabeledViewStyle: LabeledViewStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             VStack {
///                 configuration.label
///
///                 configuration.content
///             }
///         }
///     }
///
/// Now imagine you need a "bordered" style that uses the existing or default style but also adds
/// a border. You can achieve this by returning another ``StyledView`` in the custom style body.
/// This showcases the major benefit with the view style approach as it allows for multiple styles
/// to be composed and reused together. The ``StyledView`` used within custom style body
/// will use the next ``ViewStyle`` if one exists, or the default style - which is the `body` of
/// the ``StyledView``.
///
///     struct BorderedLabeledViewStyle: LabeledViewStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             LabeledView(configuration)
///                 .border(Color.red)
///         }
///     }
///
/// Now that you have created some custom styles, you can apply them with the style modifier.
/// Styles are composable which means the order you apply them does matter.
///
///     var body: some View {
///         VStack {
///             LabeledView {
///                 Text("Label")
///             } content: {
///                 Text("Content")
///             }
///             .labelStyle(VerticalLabeledViewStyle())
///
///             LabeledView {
///                 Text("Label")
///             } content: {
///                 Text("Content")
///             }
///             .labelStyle(VerticalLabeledViewStyle()) // Applied 1st
///             .labelStyle(BorderedLabeledViewStyle()) // Ignored
///
///             LabeledView {
///                 Text("Label")
///             } content: {
///                 Text("Content")
///             }
///             .labelStyle(BorderedLabeledViewStyle()) // Applied 1st
///             .labelStyle(VerticalLabeledViewStyle()) // Applied 2nd
///         }
///     }
///
@attached(peer, names: suffixed(Configuration), suffixed(Body), suffixed(Style), prefixed(Styled), suffixed(StyleModifier), suffixed(DefaultStyle))
@attached(member, names: named(_body), named(init), named(Configuration))
public macro StyledView() = #externalMacro(module: "EngineMacrosCore", type: "StyledViewMacro")

/// A protocol intended to be used with the ``@StyledView`` macro define a
/// ``ViewStyle`` and all it's related components.
@MainActor @preconcurrency
public protocol StyledView: PrimitiveView where Body == Never {

    associatedtype Configuration

    associatedtype ResolvedStyleBody: View = Never
    @ViewBuilder @MainActor @preconcurrency static func makeResolvedStyleBody(configuration: Configuration) -> ResolvedStyleBody

    associatedtype DefaultStyleBody: View
    @ViewBuilder @MainActor @preconcurrency static func makeDefaultStyleBody(configuration: Configuration) -> DefaultStyleBody

    associatedtype _Body: View
    @ViewBuilder @MainActor @preconcurrency var _body: _Body { get }
}

extension StyledView where ResolvedStyleBody == Never {

    public static func makeResolvedStyleBody(configuration: Configuration) -> Never {
        fatalError("makeResolvedStyleBody() should not be called on \(String(describing: Self.self))")
    }
}

extension StyledView {

    private nonisolated var content: StyledViewBody<Self> {
        StyledViewBody(content: self)
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        StyledViewBody<Self>._makeView(view: view[\.content], inputs: inputs)
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        StyledViewBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        StyledViewBody<Self>._viewListCount(inputs: inputs)
    }
}

private struct StyledViewBody<Content: StyledView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content._body
    }
}

@frozen
public struct _DefaultStyledView<Content: StyledView>: View {

    @usableFromInline
    var configuration: Content.Configuration

    @inlinable
    public init(_ configuration: Content.Configuration) {
        self.configuration = configuration
    }

    public var body: some View {
        Content.makeDefaultStyleBody(configuration: configuration)
    }
}
