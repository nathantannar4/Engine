//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A protocol that defines an appearance and interaction behaviour for a related ``ViewStyledView``.
///
/// To configure the style for a view hierarchy, define the desired style with ``View/styledViewStyle(_:style:)``.
///
/// # Creating Custom Styles
///
/// Start by defining a new protocol that inherits from ``ViewStyle`` and a new
/// view that conforms to ``ViewStyledView``. This style will be define the
/// configuration parameters for the styled view. Lastly, create an extension on `View`
/// that uses the ``View/styledViewStyle(_:style:)`` to apply custom styles to the view hierarchy.
///
/// If your configuration requires parameters that are views, use the ``ViewAlias``
/// for performant type-erased view parameters.
///
/// > Important: When using a configuration that has an ``ViewAlias``'s you cannot use
/// your ``ViewStyledView``. You will need to create  a new view that uses the ``ViewStyledView``
/// in it's `Body` in addition to defining the type-erased view parameters with ``View/viewAlias(_:source:)``
///
/// ```
/// protocol LabeledViewStyle: ViewStyle where Configuration == LabeledViewStyleConfiguration { }
///
/// struct LabeledViewStyleConfiguration {
///     struct Label: ViewAlias { }
///     var label: Label { .init() }
///
///     struct Content: ViewAlias { }
///     var content: Content { .init() }
/// }
///
/// struct LabeledViewBody: ViewStyledView {
///     var configuration: LabeledViewStyleConfiguration
///
///     static var defaultStyle: DefaultLabeledViewStyle { .automatic }
/// }
///
/// struct DefaultLabeledViewStyle: LabeledViewStyle {
///     func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
///         HStack(alignment: .firstTextBaseline) {
///             configuration.label
///             configuration.content
///         }
///     }
/// }
///
/// extension View {
///     func labeledViewStyle<Style: LabeledViewStyle>(_ style: Style) -> some View {
///         styledViewStyle(LabeledViewBody.self, style: style)
///     }
/// }
///
/// struct LabeledView<Label: View, Content: View>: View {
///     var label: Label
///     var content: Content
///
///     init(
///         @ViewBuilder content: () -> Content,
///         @ViewBuilder label: () -> Label
///     ) {
///         self.label = label()
///         self.content = content()
///     }
///
///     var body: some View {
///         LabeledViewBody(
///             configuration: .init()
///         )
///         .viewAlias(LabeledViewStyleConfiguration.Label.self) { label }
///         .viewAlias(LabeledViewStyleConfiguration.Content.self) { content }
///     }
/// }
///
/// extension LabeledView where
///     Label == LabeledViewStyleConfiguration.Label,
///     Content == LabeledViewStyleConfiguration.Content
/// {
///     public init(_ configuration: LabeledViewStyleConfiguration) {
///         self.label = configuration.label
///         self.content = configuration.content
///     }
/// }
/// ```
///
/// # Recursive Custom Styles
///
/// Multiple ``ViewStyle``'s can be applied recursively so long as the
/// `Body`contains another related ``ViewStyledView``.
///
/// For example, `PaddedLabeledViewStyle` is another `LabeledView`
/// but with the `padding()` modifier. Assuming no other styles were applied,
/// the `LabeledView` would then be styled with the `DefaultLabeledViewStyle`.
///
/// ```
/// struct PaddedLabeledViewStyle: LabeledViewStyle {
///     func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
///         LabeledView(configuration)
///             .padding()
///     }
/// }
/// ```
///
/// # Final Styling
///
/// The `body` of ``ViewStyledView`` is an optional requirement.
/// It can be implemented to define the final styling of a ``ViewStyledView``.
///
/// > Note: Unlike the default style which is only applied if another style is defined,
/// the styling defined by the `body` of ``ViewStyledView`` is always applied once.
///
public typealias ViewStyle = EngineCore.ViewStyle

/// A protocol that defines a view that is styled with the related ``ViewStyle``.
///
/// > Info: For more on how to create custom view styles, see ``ViewStyle``.
///
public typealias ViewStyledView = EngineCore.ViewStyledView

extension View {
    /// Statically applies the `Style` the all descendent `StyledView`
    /// views in the view hierarchy.
    ///
    /// > Info: For more on how to create custom view styles, see ``ViewStyle``.
    @inlinable
    public func styledViewStyle<
        StyledView: ViewStyledView,
        Style: ViewStyle
    >(
        _ : StyledView.Type,
        style: Style
    ) -> some View where StyledView.Configuration == Style.Configuration {
        modifier(ViewStyleModifier(StyledView.self, style: style))
    }

    /// Resets the `StyledView` to its default style.
    ///
    /// > Note: This is different than setting the default style as any previously applied styles
    /// would still be preserved.
    ///
    @inlinable
    public func defaultViewStyle<
        StyledView: ViewStyledView
    >(
        _ : StyledView.Type
    ) -> some View {
        modifier(DefaultViewStyleModifier<StyledView>())
    }
}
