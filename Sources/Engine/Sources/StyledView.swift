//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A macro that adds the necessary components of a ``StyledView``
///
/// A ``StyledView`` is an easier way to adopt the ``ViewStyle`` API
/// to transform a `View` into one that can be styled.
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
/// ```
///
/// For example, you can now defined a "bordered" style that itself returns another LabeledView.
/// This showcases the major benefit with the view style approach as it allows for multiple styles
/// to be composed and reused together.
///
///     struct BorderedLabeledViewStyle: LabeledViewStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             LabeledView(configuration)
///                 .border(Color.red)
///         }
///     }
///
/// The style and view can then be used as suggested below:
///
///     var body: some View {
///         LabeledView {
///             Text("Label")
///         } content: {
///             Text("Content")
///         }
///         .labelStyle(BorderedLabeledViewStyle())
///     }
/// ```
/// 
@attached(peer, names: suffixed(Configuration), suffixed(Body), suffixed(Style), suffixed(StyleModifier), suffixed(DefaultStyle))
@attached(member, names: named(_body), named(init))
@attached(extension, names: arbitrary)
public macro StyledView() = #externalMacro(module: "EngineMacros", type: "StyledViewMacro")

/// A protocol intended to be used with the ``@StyledView`` macro define a
/// ``ViewStyle`` and all it's related components.
public protocol StyledView: View, DynamicProperty {
    associatedtype _Body: View
    @MainActor @ViewBuilder var _body: _Body { get }
}

extension StyledView {
    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        _Body._makeView(view: view[\._body], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        _Body._makeViewList(view: view[\._body], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        _Body._viewListCount(inputs: inputs)
    }
}

@frozen
public struct _DefaultStyledView<Content: StyledView>: View {

    @usableFromInline
    var content: Content

    @inlinable
    public init(_ content: Content) {
        self.content = content
    }

    public var body: some View {
        content.body
    }
}
