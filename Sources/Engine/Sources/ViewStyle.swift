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
public protocol ViewStyle: DynamicProperty {
    associatedtype Configuration
    associatedtype Body: View

    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

/// A protocol that defines a view that is styled with the related ``ViewStyle``.
///
/// > Info: For more on how to create custom view styles, see ``ViewStyle``.
///
public protocol ViewStyledView: View {
    associatedtype Configuration
    var configuration: Configuration { get }

    associatedtype DefaultStyle: ViewStyle where DefaultStyle.Configuration == Configuration
    static var defaultStyle: DefaultStyle { get }
}

/// A modifier that statically applies the `Style` the all descendent `StyledView`
/// views in the view hierarchy.
///
/// > Info: For more on how to create custom view styles, see ``ViewStyle``.
@frozen
public struct ViewStyleModifier<
    StyledView: ViewStyledView,
    Style: ViewStyle
>: ViewModifier where StyledView.Configuration == Style.Configuration {
    @usableFromInline
    var style: Style

    @inlinable
    public init(_ : StyledView.Type = StyledView.self, style: Style) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .transformEnvironment(\.viewStyles) { value in
                value[StyledView.self].append(AnyViewStyle(style))
            }
            .modifier(InputModifier())
    }

    struct InputModifier: ViewInputsModifier {
        static func makeInputs(
            modifier: _GraphValue<Self>,
            inputs: inout _GraphInputs
        ) {
            inputs[ViewStyleInput<StyledView>.self].append(Style.Body.self)
        }
    }
}

/// A modifier that resets the `StyledView` to its default style.
///
/// > Note: This is different than setting the default style as any previously applied styles
/// would still be preserved.
///
@frozen
public struct DefaultViewStyleModifier<
    StyledView: ViewStyledView
>: ViewModifier {

    @inlinable
    public init() {
    }

    public func body(content: Content) -> some View {
        content
            .transformEnvironment(\.viewStyles) { value in
                value[StyledView.self].removeAll()
            }
            .modifier(InputModifier())
    }

    struct InputModifier: ViewInputsModifier {
        static func makeInputs(
            modifier: _GraphValue<Self>,
            inputs: inout _GraphInputs
        ) {
            inputs[ViewStyleInput<StyledView>.self].removeAll()
            inputs[ViewStyleContext<StyledView>.self] = nil
        }
    }
}

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

private struct ViewStylesKey: EnvironmentKey {
    static let defaultValue = ViewStylesBox()
}

extension EnvironmentValues {
    fileprivate var viewStyles: ViewStylesBox {
        get { self[ViewStylesKey.self] }
        set { self[ViewStylesKey.self] = newValue }
    }
}

private struct ViewStylesBox {
    private var storage: [UnsafeRawPointer: [AnyViewStyle]] = [:]

    fileprivate subscript<ID: ViewStyledView>(
        _ : ID.Type
    ) -> [AnyViewStyle] {
        get { storage[unsafeBitCast(ID.self, to: UnsafeRawPointer.self)] ?? [] }
        set { storage[unsafeBitCast(ID.self, to: UnsafeRawPointer.self)] = newValue }
    }
}

private struct ViewStyleInput<ID: ViewStyledView>: ViewInputKey {
    typealias Value = [Any.Type] // ViewStyle.Body Type
    static var defaultValue: [Any.Type] { [] }
}

private struct ViewStyleContext<ID: ViewStyledView>: ViewInputKey {
    typealias Value = Any.Type?
    static var defaultValue: Any.Type? { nil }
}

extension ViewStyledView where Body == Never {
    public var body: Never {
        bodyError()
    }
}

extension ViewStyledView {
    private var content: ViewStyledViewBody<Self> {
        ViewStyledViewBody(configuration: configuration)
    }

    private var defaultContent: ViewStyledViewDefaultBody<Self> {
        ViewStyledViewDefaultBody(
            style: Self.defaultStyle,
            configuration: configuration
        )
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        if Body.self != Never.self,
            inputs.base[ViewStyleContext<Self>.self] != Self.self
        {
            var inputs = inputs
            inputs.base[ViewStyleContext<Self>.self] = Self.self
            return Body._makeView(view: view[\.body], inputs: inputs)
        } else if inputs.base[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewBody<Self>._makeView(view: view[\.content], inputs: inputs)
        } else {
            return ViewStyledViewDefaultBody<Self>._makeView(view: view[\.defaultContent], inputs: inputs)
        }
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        if Body.self != Never.self,
            inputs.base[ViewStyleContext<Self>.self] != Self.self
        {
            var inputs = inputs
            inputs.base[ViewStyleContext<Self>.self] = Self.self
            return Body._makeViewList(view: view[\.body], inputs: inputs)
        } else if inputs.base[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
        } else {
            return ViewStyledViewDefaultBody<Self>._makeViewList(view: view[\.defaultContent], inputs: inputs)
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        if Body.self != Never.self,
            inputs.base[ViewStyleContext<Self>.self] != Self.self
        {
            var inputs = inputs
            inputs.base[ViewStyleContext<Self>.self] = Self.self
            return Body._viewListCount(inputs: inputs)
        } else if inputs.base[ViewStyleInput<Self>.self].last != nil {
            return ViewStyledViewBody<Self>._viewListCount(inputs: inputs)
        } else {
            return ViewStyledViewDefaultBody<Self>._viewListCount(inputs: inputs)
        }
    }
}

private struct ViewStyledViewDefaultBody<StyledView: ViewStyledView>: View {
    var style: StyledView.DefaultStyle
    var configuration: StyledView.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

private struct ViewStyledViewBody<StyledView: ViewStyledView>: View {
    var configuration: StyledView.Configuration

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
>: View {
    var style: AnyViewStyle
    var configuration: StyledView.Configuration

    @MainActor var content: ViewStyleBody {
        style.body(as: ViewStyleBody.self, configuration: configuration)
    }

    var body: Never {
        bodyError()
    }

    static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        var inputs = inputs
        var types = inputs.base[ViewStyleInput<StyledView>.self]
        let type = types.popLast()!
        inputs.base[ViewStyleInput<StyledView>.self] = types
        if types.isEmpty {
            inputs.base[ViewStyleContext<StyledView>.self] = nil
        }

        func project<T>(_ type: T.Type) -> _ViewOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewOutputsVisitor(
                view: view,
                inputs: inputs
            )
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(type, do: project)
    }

    static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        var inputs = inputs
        var types = inputs.base[ViewStyleInput<StyledView>.self]
        let type = types.popLast()!
        inputs.base[ViewStyleInput<StyledView>.self] = types
        if types.isEmpty {
            inputs.base[ViewStyleContext<StyledView>.self] = nil
        }

        func project<T>(_ type: T.Type) -> _ViewListOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsVisitor(
                view: view,
                inputs: inputs
            )
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(type, do: project)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        var inputs = inputs
        var types = inputs.base[ViewStyleInput<StyledView>.self]
        let type = types.popLast()!
        inputs.base[ViewStyleInput<StyledView>.self] = types
        if types.isEmpty {
            inputs.base[ViewStyleContext<StyledView>.self] = nil
        }

        func project<T>(_ type: T.Type) -> Int? {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsCountVisitor(inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        return _openExistential(type, do: project)
    }
}

struct AnyViewStyle {
    private class AnyViewStyleStorageBase {
        @MainActor func visit<Configuration, Body>(
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
                Body.self == Style.Body.self,
                "\(Body.self) != \(Style.Body.self)"
            )
            let configuration = unsafeBitCast(configuration, to: Style.Configuration.self)
            let body = style.makeBody(configuration: configuration)
            return unsafeBitCast(body, to: Body.self)
        }
    }

    private let storage: AnyViewStyleStorageBase

    init<Style: ViewStyle>(_ style: Style) {
        self.storage = AnyViewStyleStorage(style)
    }

    @MainActor func body<Configuration, Body>(
        as body: Body.Type,
        configuration: Configuration
    ) -> Body {
        storage.visit(as: Body.self, configuration: configuration)
    }
}

private struct ViewOutputsVisitor<
    StyledView: ViewStyledView,
    ViewStyleBody: View
>: ViewVisitor {

    var view: _GraphValue<AnyViewStyledView<StyledView, ViewStyleBody>>
    var inputs: _ViewInputs

    var outputs: _ViewOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(
            view,
            to: _GraphValue<AnyViewStyledView<StyledView, Content>>.self
        )
        outputs = Content._makeView(view: view[\.content], inputs: inputs)
    }
}

private struct ViewListOutputsVisitor<
    StyledView: ViewStyledView,
    ViewStyleBody: View
>: ViewVisitor {

    var view: _GraphValue<AnyViewStyledView<StyledView, ViewStyleBody>>
    var inputs: _ViewListInputs

    var outputs: _ViewListOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(
            view,
            to: _GraphValue<AnyViewStyledView<StyledView, Content>>.self
        )
        outputs = Content._makeViewList(view: view[\.content], inputs: inputs)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewListOutputsCountVisitor: ViewVisitor {
    var inputs: _ViewListCountInputs

    var outputs: Int?

    mutating func visit<Content>(type: Content.Type) where Content: View {
        outputs = Content._viewListCount(inputs: inputs)
    }
}
