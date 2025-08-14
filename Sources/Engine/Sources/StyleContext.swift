//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

/// A ``StyleContext`` is a ``ViewInput`` that can be used to
/// conditionally apply styling and modifiers to a view based on the context
/// they are in. Such as being contained with a `List` or `ScrollView`.
///
/// Built-in SwiftUI styles include:
///  - ``NoStyleContext``
///  - ``ScrollViewStyleContext``
///  - ``ListStyleContext``/``InsetGroupedListStyleContext``
///  - ``FormStyleContext``
///  - ``ToolbarStyleContext``
///  - ``SidebarStyleContext``/``NavigationViewStyleContext``
///
/// Use the ``View/styleContext(_:)`` on an view to apply a context.
///
/// See Also:
///  - ``StyleContextConditionalModifier``
///  - ``StyleContextModifier``
///
public protocol StyleContext {
    /// Alternative style contexts that should also be matched against
    static var aliases: [StyleContext.Type] { get }

    /// Returns if the style context matches
    static func evaluate(_ input: StyleContextInputs) -> Bool
}

extension View {

    /// A modifier that statically applies the `StyleContext`to the view hierarchy.
    ///
    /// > Info: For more on how to create custom style context, see ``StyleContext``.
    @inlinable
    public func styleContext<Context: StyleContext>(_ : Context) -> some View {
        modifier(StyleContextModifier<Context>())
    }
}

/// An opaque ``StyleContext`` wrapper for custom contexts and built-in SwiftUI contexts
public struct StyleContextInputs {
    public var type: Any.Type

    /// Returns `true` when the inputs match the style `S`
    public func contains<Context: StyleContext>(_: Context.Type) -> Bool {
        let typeName = _typeName(type, qualified: false)
        return Context.contains(typeName: typeName)
    }
}

// MARK: - StyleContext

/// The default style context
public struct NoStyleContext: StyleContext { }
extension StyleContext where Self == NoStyleContext {
    public static var none: NoStyleContext { .init() }
}

// MARK: - ScrollViewStyleContext

/// The style context of a `ScrollView`
public struct ScrollViewStyleContext: StyleContext { }
extension StyleContext where Self == ScrollViewStyleContext {
    public static var scrollView: ScrollViewStyleContext { .init() }
}

// MARK: - ListStyleContext

/// The style context of a `List`
public struct ListStyleContext: StyleContext {
    public static var aliases: [any StyleContext.Type] {
        [
            InsetGroupedListStyleContext.self,
            FormStyleContext.self,
        ]
    }
}
extension StyleContext where Self == ListStyleContext {
    public static var list: ListStyleContext { .init() }
}

/// The style context of a `List` with the `InsetGroupedListStyle`
public struct InsetGroupedListStyleContext: StyleContext { }
extension StyleContext where Self == InsetGroupedListStyleContext {
    public static var insetGroupedList: InsetGroupedListStyleContext { .init() }
}

/// The style context of a `Form`
public struct FormStyleContext: StyleContext {
    public static var aliases: [any StyleContext.Type] {
        [
            GroupedFormStyleContext.self,
            ColumnsFormStyleContext.self,
        ]
    }
}
extension StyleContext where Self == FormStyleContext {
    public static var form: FormStyleContext { .init() }
}

public struct GroupedFormStyleContext: StyleContext { }
extension StyleContext where Self == GroupedFormStyleContext {
    public static var form: GroupedFormStyleContext { .init() }
}

public struct ColumnsFormStyleContext: StyleContext { }
extension StyleContext where Self == ColumnsFormStyleContext {
    public static var form: ColumnsFormStyleContext { .init() }
}


// MARK: - ToolbarStyleContext

/// The style context of a `Toolbar`
public struct ToolbarStyleContext: StyleContext { }
extension StyleContext where Self == ToolbarStyleContext {
    public static var toolbar: ToolbarStyleContext { .init() }
}

// MARK: - SidebarStyleContext

/// The style context of a `NavigationView`/`NavigationSplitView`
public struct SidebarStyleContext: StyleContext { }
extension StyleContext where Self == SidebarStyleContext {
    public static var sidebar: SidebarStyleContext { .init() }
}

/// The style context of a `NavigationView`/`NavigationSplitView`
public struct NavigationViewStyleContext: StyleContext {
    public static var aliases: [any StyleContext.Type] {
        [
            SidebarStyleContext.self,
        ]
    }
}
extension StyleContext where Self == NavigationViewStyleContext {
    public static var navigationView: NavigationViewStyleContext { .init() }
}

extension StyleContext {
    public static var aliases: [StyleContext.Type] { [] }

    public static func evaluate(_ input: StyleContextInputs) -> Bool {
        input.contains(self)
    }

    static func matches(typeName: String) -> Bool {
        if typeName == _typeName(self, qualified: false) {
            return true
        }
        return aliases.contains(where: {
            $0.matches(typeName: typeName)
        })
    }

    static func contains(typeName: String) -> Bool {
        if typeName.hasPrefix("TupleStyleContext<(") {
            // TupleStyleContext<( = 19 >) = -2
            let typeNames = typeName[typeName.index(typeName.startIndex, offsetBy: 19)..<typeName.index(typeName.endIndex, offsetBy: -2)]
                .components(separatedBy: ", ")
                .filter { $0 != "NoStyleContext" }
            return typeNames.contains(where: {
                contains(typeName: $0)
            })
        }
        return matches(typeName: typeName)
    }
}

/// A modifier that applies the `Modifier` only when the`StyleContext` matches
/// the current style context of the view.
@frozen
public struct StyleContextConditionalModifier<
    Context: StyleContext,
    Modifier: ViewModifier
>: ViewModifier {

    @usableFromInline
    var modifier: Modifier

    @inlinable
    public init(predicate: Context, @ViewModifierBuilder modifier: () -> Modifier) {
        self.modifier = modifier()
    }

    public func body(content: Content) -> some View {
        content
            .modifier(
                ViewInputConditionalModifier<StyleContextCondition<Context>, Modifier, EmptyModifier> {
                    modifier
                }
            )
    }
}

/// A modifier that statically applies the `StyleContext`to the view hierarchy.
///
/// See Also:
///  - ``StyleContext``
@frozen
public struct StyleContextModifier<
    Context: StyleContext
>: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .input(StyleContextInputValue<Context>.self)
            .modifier(
                StaticConditionalModifier(IsDefault.self) {
                    SystemDefaultModifier()
                }
            )
    }

    private struct IsDefault: StaticCondition {
        static var value: Bool {
            Context.self == NoStyleContext.self
        }
    }

    private struct SystemDefaultModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                ._defaultContext()
        }
    }
}

private struct StyleContextInput: ViewInputKey {
    static let defaultValue: StyleContextInputLayout = StyleContextInputLayout(metadata: (NoStyleContext.self, 0))
}

private struct StyleContextInputValue<Context: StyleContext>: ViewInput {
    typealias Key = StyleContextInput
    static var value: Key.Value {
        StyleContextInputLayout(metadata: (Context.self, 0))
    }
}

@frozen
public struct StyleContextCondition<
    Context: StyleContext
>: ViewInputsCondition {

    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        let styleContext = inputs["StyleContextInput", StyleContextInputLayout.self]?.context ?? NoStyleContext.self
        let input = StyleContextInputs(type: styleContext)
        return Context.evaluate(input)
    }
}

private struct StyleContextInputLayout {
    var metadata: (Any.Type, UInt)

    var context: Any.Type? {
        // Handle SwiftUI contexts
        if let context = swift_getStructGenerics(for: metadata.0)?.first {
            return context
        }
        // Handle custom contexts
        return metadata.0
    }
}

@frozen
public struct _StyleContextLogModifier: ViewInputsModifier {

    @inlinable
    public init() { }

    public static func makeInputs(inputs: inout ViewInputs) {
        #if DEBUG
        let styleContext = inputs["StyleContextInput", StyleContextInputLayout.self]?.context ?? NoStyleContext.self
        let log = """
            === StyleContext ===
            \(_typeName(styleContext, qualified: false))
            """
        os_log(.debug, "%@", log)
        #endif
    }
}

// MARK: - Previews

struct PreviewStyleContext: StyleContext { }

struct StyleContext_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewCustomView {
                Text("Hello, World")
            }
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle(),
                predicate: PreviewStyleContext()
            )

            PreviewCustomView {
                Text("Hello, World")
            }
            .styledViewStyle(
                PreviewCustomViewBody.self,
                style: BorderedPreviewCustomViewStyle(),
                predicate: PreviewStyleContext()
            )
            .styleContext(PreviewStyleContext())
        }
    }
}
