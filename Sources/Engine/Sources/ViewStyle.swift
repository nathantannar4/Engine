//
// Copyright (c) Nathan Tannar
//

import SwiftUI

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
/// > Tip: You can use the ``@StyledView`` macro to automate the creation of a styled view for any `View`
///
/// ```
/// protocol LabeledViewStyle: ViewStyle where Configuration == LabeledViewStyleConfiguration {
///     associatedtype Configuration = Configuration
/// }
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
///     func makeBody(configuration: Configuration) -> some View {
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
/// # Adding Custom Styles
///
/// Now imagine you need a "vertical" style that uses a `VStack` rather than an `HStack`.
/// With a custom style you can achieve this in a performant and type safe way.
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
/// a border. You can achieve this by returning related ``ViewStyledView`` in the custom style body.
/// This showcases the major benefit with the view style approach as it allows for multiple styles
/// to be composed and reused together. The ``ViewStyledView`` used within custom style body
/// will use the next ``ViewStyle`` if one exists, or the default style.
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
/// # Final Styling
///
/// The `body` of ``ViewStyledView`` is an optional requirement.
/// It can be implemented to define the final styling of a ``ViewStyledView``.
///
/// > Note: Unlike the default style which is only applied if another style is defined,
/// the styling defined by the `body` of ``ViewStyledView`` is always applied once.
///
/// > Note: ``ViewStyle``'s stack when applied to a view, so the order you apply them
/// does matter.
///
@MainActor @preconcurrency
public protocol ViewStyle: DynamicProperty {
    associatedtype Configuration
    associatedtype Body: View

    @ViewBuilder @MainActor @preconcurrency func makeBody(configuration: Configuration) -> Body
}

/// A protocol that defines a view that is styled with the related ``ViewStyle``.
///
/// > Info: For more on how to create custom view styles, see ``ViewStyle`` and ``@StyledView``.
///
@MainActor @preconcurrency
public protocol ViewStyledView: PrimitiveView {
    associatedtype Configuration
    nonisolated var configuration: Configuration { get }

    associatedtype DefaultStyle: ViewStyle where DefaultStyle.Configuration == Configuration
    @MainActor @preconcurrency static var defaultStyle: DefaultStyle { get }
}

/// A modifier that statically applies the `Style` the all descendent `StyledView`
/// views in the view hierarchy.
///
/// > Info: For more on how to create custom view styles, see ``ViewStyle`` and ``@StyledView``.
@frozen
public struct ViewStyleModifier<
    StyledView: ViewStyledView,
    Style: ViewStyle
>: ViewModifier where StyledView.Configuration == Style.Configuration {

    // Wrap in a non `DynamicProperty` to avoid styles `DynamicProperty` resolution
    @frozen
    @usableFromInline
    struct Storage {
        var style: Style

        @usableFromInline
        init(style: Style) {
            self.style = style
        }
    }

    @usableFromInline
    var storage: Storage

    @inlinable
    public init(_ : StyledView.Type = StyledView.self, style: Style) {
        self.storage = Storage(style: style)
    }

    public func body(content: Content) -> some View {
        content
            .transformEnvironment(\.viewStyles) { value in
                value[StyledView.self].append(AnyViewStyle(storage.style))
            }
            .modifier(ViewStyleWritingModifier<Style>())
    }

    struct ViewStyleWritingModifier<S: ViewStyle>: ViewModifier {
        func body(content: Content) -> some View {
            content
                .modifier(InputModifier())
                .modifier(UnaryViewModifier())
        }

        struct InputModifier: GraphInputsModifier {
            nonisolated static func makeInputs(
                modifier: _GraphValue<Self>,
                inputs: inout _GraphInputs
            ) {
                inputs[ViewStyleInput<StyledView>.self].append(S.self)
            }
        }
    }
}

extension View {
    /// Statically applies the `Style` the all descendent `StyledView`
    /// views in the view hierarchy.
    ///
    /// > Info: For more on how to create custom view styles, see ``ViewStyle`` and ``@StyledView``.
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

    /// Statically applies the `Style` the all descendent `StyledView`
    /// views in the view hierarchy when the`StyleContext` matches
    /// the current style context of the view.
    ///
    /// > Info: For more on how to create custom view styles, see ``ViewStyle`` and ``@StyledView``.
    /// > Info: For more on how to create custom style context, see ``StyleContext``.
    @inlinable
    public func styledViewStyle<
        StyledView: ViewStyledView,
        Style: ViewStyle,
        Context: StyleContext
    >(
        _ : StyledView.Type,
        style: Style,
        predicate: Context
    ) -> some View where StyledView.Configuration == Style.Configuration {
        modifier(
            StyleContextConditionalModifier(predicate: predicate) {
                ViewStyleModifier(StyledView.self, style: style)
            }
        )
    }
}

private struct ViewStylesKey: EnvironmentKey {
    static let defaultValue = ViewStylesBox()
}

extension EnvironmentValues {
    fileprivate var viewStyles: ViewStylesBox {
        get { self[ViewStylesKey.self] }
        set { self[ViewStylesKey.self] = newValue }
    }
}

private struct ViewStylesBox: @unchecked Sendable {
    private var storage: [UnsafeRawPointer: [AnyViewStyle]] = [:]

    fileprivate subscript<ID: ViewStyledView>(
        _ : ID.Type
    ) -> [AnyViewStyle] {
        get { storage[unsafeBitCast(ID.self, to: UnsafeRawPointer.self)] ?? [] }
        set { storage[unsafeBitCast(ID.self, to: UnsafeRawPointer.self)] = newValue }
    }
}

private struct ViewStyleInput<ID: ViewStyledView>: ViewInputKey {
    typealias Value = [any ViewStyle.Type]
    static var defaultValue: Value { [] }
}

private struct ViewStyleContext<ID: ViewStyledView>: ViewInputKey {
    enum Value {
        case unstyled
        case styling
        case styled
    }
    static var defaultValue: Value { .unstyled }
}

extension ViewStyledView {

    private nonisolated var _body: ViewStyledViewBody<Self> {
        ViewStyledViewBody(content: self)
    }

    private nonisolated var content: ViewStyledViewStyledBody<Self> {
        ViewStyledViewStyledBody(configuration: configuration)
    }

    private nonisolated var defaultContent: ViewStyledViewDefaultBody<Self> {
        ViewStyledViewDefaultBody(configuration: configuration)
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        if Body.self != Never.self,
            inputs[ViewStyleContext<Self>.self] == .unstyled
        {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .styling
            return ViewStyledViewBody<Self>._makeView(view: view[\._body], inputs: inputs)
        } else if inputs[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewStyledBody<Self>._makeView(view: view[\.content], inputs: inputs)
        } else {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .unstyled
            return ViewStyledViewDefaultBody<Self>._makeView(view: view[\.defaultContent], inputs: inputs)
        }
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        if Body.self != Never.self,
           inputs[ViewStyleContext<Self>.self] == .unstyled
        {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .styling
            return ViewStyledViewBody<Self>._makeViewList(view: view[\._body], inputs: inputs)
        } else if inputs[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewStyledBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
        } else {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .unstyled
            return ViewStyledViewDefaultBody<Self>._makeViewList(view: view[\.defaultContent], inputs: inputs)
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        if Body.self != Never.self,
           inputs[ViewStyleContext<Self>.self] == .unstyled
        {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .styling
            return ViewStyledViewBody<Self>._viewListCount(inputs: inputs)
        } else if inputs[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewStyledBody<Self>._viewListCount(inputs: inputs)
        } else {
            var inputs = inputs
            inputs[ViewStyleContext<Self>.self] = .unstyled
            return ViewStyledViewDefaultBody<Self>._viewListCount(inputs: inputs)
        }
    }
}

private struct ViewStyledViewBody<
    StyledView: ViewStyledView
>: View {

    nonisolated(unsafe) var content: StyledView

    var body: some View {
        content.body
    }
}

private struct ViewStyledViewDefaultBody<
    StyledView: ViewStyledView
>: View {

    nonisolated(unsafe) var configuration: StyledView.Configuration

    var body: some View {
        StyledView.defaultStyle.makeBody(configuration: configuration)
    }
}

private struct ViewStyledViewStyledBody<
    StyledView: ViewStyledView
>: View {

    nonisolated(unsafe) var configuration: StyledView.Configuration

    @Environment(\.viewStyles) var viewStyles

    var body: some View {
        var viewStyles = viewStyles
        let style = viewStyles[StyledView.self].popLast()!
        AnyViewStyledView<StyledView, Never>(
            style: style,
            configuration: configuration
        )
        .environment(\.viewStyles, viewStyles)
    }
}

private struct AnyViewStyledView<
    StyledView: ViewStyledView,
    ViewStyleBody: View
>: PrimitiveView {

    nonisolated(unsafe) var style: AnyViewStyle
    nonisolated(unsafe) var configuration: StyledView.Configuration

    nonisolated var content: ViewStyleBody {
        style.body(as: ViewStyleBody.self, configuration: configuration)
    }

    nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        var inputs = inputs
        var styles = inputs[ViewStyleInput<StyledView>.self]
        let style = styles.popLast()!
        inputs[ViewStyleInput<StyledView>.self] = styles
        if styles.isEmpty {
            inputs[ViewStyleContext<StyledView>.self] = .styled
        }

        func project<Style: ViewStyle>(_ : Style.Type) -> _ViewOutputs {
            let view = unsafeBitCast(
                view,
                to: _GraphValue<AnyViewStyledView<StyledView, AnyViewStyledViewBody<Style>>>.self
            )
            return AnyViewStyledViewBody<Style>._makeView(
                view: view[\.content],
                inputs: inputs
            )
        }
        return _openExistential(style, do: project)
    }

    nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        var inputs = inputs
        var styles = inputs[ViewStyleInput<StyledView>.self]
        let style = styles.popLast()!
        inputs[ViewStyleInput<StyledView>.self] = styles
        if styles.isEmpty {
            inputs[ViewStyleContext<StyledView>.self] = .styled
        }

        func project<Style: ViewStyle>(_ : Style.Type) -> _ViewListOutputs {
            let view = unsafeBitCast(
                view,
                to: _GraphValue<AnyViewStyledView<StyledView, AnyViewStyledViewBody<Style>>>.self
            )
            return AnyViewStyledViewBody<Style>._makeViewList(
                view: view[\.content],
                inputs: inputs
            )
        }
        return _openExistential(style, do: project)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        var inputs = inputs
        var styles = inputs[ViewStyleInput<StyledView>.self]
        let style = styles.popLast()!
        inputs[ViewStyleInput<StyledView>.self] = styles
        if styles.isEmpty {
            inputs[ViewStyleContext<StyledView>.self] = .styled
        }

        func project<Style: ViewStyle>(_ : Style.Type) -> Int? {
            return AnyViewStyledViewBody<Style>._viewListCount(
                inputs: inputs
            )
        }
        return _openExistential(style, do: project)
    }
}

private struct AnyViewStyledViewBody<Style: ViewStyle>: View {

    nonisolated(unsafe) var style: Style
    nonisolated(unsafe) var configuration: Style.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

struct AnyViewStyle: @unchecked Sendable {
    private class AnyViewStyleStorageBase {
        func visit<Configuration, Body>(
            as body: Body.Type,
            configuration: Configuration
        ) -> Body {
            fatalError("abstract")
        }
    }

    private class AnyViewStyleStorage<Style: ViewStyle>: AnyViewStyleStorageBase {
        let style: Style
        init(_ style: Style) {
            self.style = style
        }

        override func visit<Configuration, Body>(
            as body: Body.Type,
            configuration: Configuration
        ) -> Body {
            assert(
                Configuration.self == Style.Configuration.self,
                "\(Configuration.self) != \(Style.Configuration.self)"
            )
            assert(
                Body.self == AnyViewStyledViewBody<Style>.self,
                "\(Body.self) != \(Style.Body.self)"
            )
            let configuration = unsafeBitCast(configuration, to: Style.Configuration.self)
            let body = AnyViewStyledViewBody(
                style: style,
                configuration: configuration
            )
            return unsafeBitCast(body, to: Body.self)
        }
    }

    private let storage: AnyViewStyleStorageBase

    init<Style: ViewStyle>(_ style: Style) {
        self.storage = AnyViewStyleStorage(style)
    }

    func body<Configuration, Body>(
        as body: Body.Type,
        configuration: Configuration
    ) -> Body {
        storage.visit(as: Body.self, configuration: configuration)
    }
}

// MARK: - Previews

protocol PreviewCustomViewStyle: ViewStyle where Configuration == PreviewCustomViewStyleConfiguration {
    associatedtype Configuration = Configuration
}

struct PreviewCustomViewStyleConfiguration {
    struct Content: ViewAlias { }
    var content: Content { .init() }
}

struct PreviewCustomView<Content: View>: View {

    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init(
        configuration: PreviewCustomViewStyleConfiguration
    ) where Content == PreviewCustomViewStyleConfiguration.Content {
        self.content = configuration.content
    }

    var body: some View {
        PreviewCustomViewBody(
            configuration: PreviewCustomViewStyleConfiguration()
        )
        .viewAlias(PreviewCustomViewStyleConfiguration.Content.self) {
            content
        }
    }
}

struct PreviewCustomViewBody: ViewStyledView {
    var configuration: PreviewCustomViewStyleConfiguration

    var body: some View {
        PreviewCustomView(configuration: configuration)
            .background(Color.yellow.opacity(0.25))
    }

    static var defaultStyle: DefaultPreviewCustomViewStyle { .init() }
}

struct DefaultPreviewCustomViewStyle: PreviewCustomViewStyle {
    func makeBody(configuration: PreviewCustomViewStyleConfiguration) -> some View {
        configuration.content
    }
}

struct BorderColorKey: EnvironmentKey {
    static let defaultValue: Color = .accentColor
}

extension EnvironmentValues {
    var borderColor: Color {
        get { self[BorderColorKey.self] }
        set { self[BorderColorKey.self] = newValue }
    }
}

struct BorderedPreviewCustomViewStyle: PreviewCustomViewStyle {

    @Environment(\.borderColor) var borderColor

    func makeBody(configuration: PreviewCustomViewStyleConfiguration) -> some View {
        PreviewCustomView(configuration: configuration)
            .padding()
            .border(borderColor)
    }
}

struct ViewStyledView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewCustomView {
                Text("Hello, World")
            }

            PreviewCustomView {
                Text("Hello, World")
            }
            .environment(\.borderColor, .green)
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle()
            )
            .environment(\.borderColor, .red)

            PreviewCustomView {
                Text("Hello, World")
            }
            .environment(\.borderColor, .green)
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle()
            )
            .environment(\.borderColor, .yellow)
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle()
            )
            .environment(\.borderColor, .red)

            PreviewCustomView {
                PreviewCustomView {
                    PreviewCustomView {
                        Text("Hello, World")
                    }
                    .padding()
                }
            }
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle()
            )
        }
    }
}
