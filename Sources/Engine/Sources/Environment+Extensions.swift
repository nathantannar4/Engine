//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

/// Accessors to internal keys ``Engine.EnvironmentKeyVisitor``
extension EnvironmentValues {

    /// Whether the view is rendered within a glass effect.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public var hasGlassEffect: Bool {
        self["__Key_hasGlassEffect", default: false]
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// The hosting controller that is hosting the view, if available.
    public var hostingController: UIViewController? {
        if #available(iOS 17.0, tvOS 17.0, *) {
            return self["WithCurrentHostingControllerKey"]
        } else if let context = self["ToolbarUpdateContextKey", as: Any.self] {
            return try? swift_getFieldValue("targetController", UIViewController?.self, context)
        }
        return nil
    }
    #endif

    /// The value for the ``.labelsHidden(_)`` modifier
    public var labelsHidden: Bool {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return labelsVisibility == .hidden
        }
        return self["LabelsHiddenKey", default: false]
    }

    /// The value for the ``.foregroundStyle(_)``/``.foregroundColor(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var foregroundStyle: AnyShapeStyle {
        self["ForegroundStyleKey", default: AnyShapeStyle(.foreground)]
    }

    /// The color resolved from the ``.foregroundStyle(_)``/``.foregroundColor(_)`` modifier
    public var foregroundColor: Color? {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
            let foregroundStyle = self["ForegroundStyleKey", as: AnyShapeStyle.self]
        {
            return foregroundStyle.color(in: self)
        }
        return self["ForegroundColorKey"]
    }

    /// The value for the ``.tint(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var tintStyle: AnyShapeStyle {
        self["TintKey", default: AnyShapeStyle(.tint)]
    }

    /// The color for the ``.tint(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var tint: Color? {
        return tintStyle.color(in: self)
    }

    /// The tint color resolved from the ``.tint(_)`` or ``.accentColor(_)`` modifier
    public var tintColor: Color? {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), let tint {
            return tint
        }
        return accentColor
    }

    /// The value for the ``.accentColor(_)`` modifier
    public var accentColor: Color {
        self["AccentColorKey", default: Color.accentColor]
    }

    /// The value for the ``.underline(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var underlineStyle: Text.LineStyle? {
        self["UnderlineStyleKey"]
    }

    /// The value for the ``.strikethrough(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var strikethroughStyle: Text.LineStyle? {
        self["StrikethroughStyleKey"]
    }

    /// The value for the ``.kerning(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var kerning: CGFloat {
        self["DefaultKerningKey", default: 0]
    }

    /// The value for the ``.tracking(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var tracking: CGFloat {
        self["DefaultTrackingKey", default: 0]
    }

    /// The value for the ``.baselineOffset(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var baselineOffset: CGFloat {
        self["DefaultBaselineOffsetKey", default: 0]
    }

    /// The lower bound for the ``.lineLimit(_)`` modifier, when a range is specified
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var lineLimitMininum: Int? {
        self["LowerLineLimitKey"]
    }

    /// The range of lines for the ``.lineLimit(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var lineLimitRange: ClosedRange<Int>? {
        let min = lineLimitMininum ?? 0
        let max = lineLimit ?? Int.max
        return min...max
    }

    /// The value for the ``.textScale(_)`` modifier
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public var textScale: Text.Scale {
        self["TextScaleKey", default: Text.Scale.default]
    }

    /// The value for the ``.imageScale(_)`` modifier
    @available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
    public var imageScale: Image.Scale? {
        self["ImageScaleKey"]
    }

    /// The value for the ``.textInputAutocapitalization(_)`` modifier
    public var textInputAutocapitalizationBehaviour: TextInputAutocapitalizationBehaviour? {
        get {
            if let behaviour = self[TextInputAutocapitalizationBehaviour.Key.self] {
                return behaviour
            }
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                return textInputAutocapitalization?.behaviour
            }
            #endif
            return nil
        }
        set {
            self[TextInputAutocapitalizationBehaviour.Key.self] = newValue
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// The value for the ``.textInputAutocapitalization(_)`` modifier
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public var textInputAutocapitalization: TextInputAutocapitalization? {
        self["TextInputAutocapitalizationKey"]
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// The value for the ``.textInputAutocapitalization(_)`` modifier
    public var autocapitalizationType: UITextAutocapitalizationType? {
        guard let behaviour = textInputAutocapitalizationBehaviour else { return nil }
        return UITextAutocapitalizationType(behaviour)
    }

    /// The value for the ``.textContentType(_)`` modifier
    public var textContentType: UITextContentType? {
        let rawValue = self["TextContentTypeKey", as: UITextContentType.RawValue.self]
        return rawValue.map({ UITextContentType(rawValue: $0) })
    }

    /// The value for the ``.keyboardType(_)`` modifier
    public var keyboardType: UIKeyboardType {
        self["KeyboardTypeKey", default: UIKeyboardType.default]
    }

    /// The return key type resolved from the ``.submitLabel(_)``/``.submitRole(_)`` modifier
    public var returnKeyType: UIReturnKeyType? {
        guard let role = submitLabelRole else { return nil }
        return UIReturnKeyType(role)
    }
    #endif

    /// The value for the `dynamicTypeSize`/`sizeCategory`'s `isAccessibilitySize`
    public var isAccesssibilitySize: Bool {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return dynamicTypeSize.isAccessibilitySize
        }
        switch sizeCategory {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    /// The action for the ``.onSubmit(_)`` modifier
    public var submit: SubmitAction? {
        get {
            if let submitAction = self[SubmitAction.Key.self] {
                return submitAction
            }
            return self["__Key_triggerSubmission"]
        }
        set {
            self[SubmitAction.Key.self] = newValue
        }
    }

    /// The value for the ``.submitLabel(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var submitLabel: SubmitLabel? {
        self["SubmitLabelKey"]
    }

    /// The role for the ``.submitLabel(_)``/``.submitRole(_)`` modifier
    public var submitLabelRole: SubmitLabelRole? {
        get {
            if let role = self[SubmitLabelRole.Key.self] {
                return role
            }
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return submitLabel?.role
            }
            return nil
        }
        set {
            self[SubmitLabelRole.Key.self] = newValue
        }
    }

    /// The value for the display corner radius
    public var displayCornerRadius: CGFloat? {
        self["DisplayCornerRadiusKey"]
    }

    /// The contrast associated with the color scheme of this environment
    public var colorSchemeContrast: ColorSchemeContrast {
        get { _colorSchemeContrast }
        set { _colorSchemeContrast = newValue }
    }

    /// The value for the color scheme of the system
    public var systemColorScheme: ColorScheme {
        self["SystemColorSchemeKey", default: .light]
    }

    /// The value for the ``.preferredColorScheme(_)`` modifier
    public var preferredColorScheme: ColorScheme? {
        self["ExplicitPreferredColorSchemeKey"]
    }
}

#if !os(macOS) && !os(watchOS)
extension EnvironmentValues {

    /// Creates environment values from the traits of a `UITraitCollection`.
    public init(_ traitCollection: UITraitCollection) {
        self = EnvironmentValues().merging(traitCollection)
    }

    /// Updates the environment values with the traits of a `UITraitCollection`,
    /// such as the color scheme, size classes, layout direction and dynamic type size.
    public mutating func merge(_ traitCollection: UITraitCollection) {
        if #available(iOS 14.0, tvOS 14.0, *), let colorScheme = ColorScheme(traitCollection.userInterfaceStyle) {
            self.colorScheme = colorScheme
        } else {
            switch traitCollection.userInterfaceStyle {
            case .light:
                colorScheme = .light
            case .dark:
                colorScheme = .dark
            default:
                break
            }
        }
        #if !os(tvOS)
        if #available(iOS 14.0, *) {
            horizontalSizeClass = UserInterfaceSizeClass(traitCollection.horizontalSizeClass)
        } else {
            switch traitCollection.horizontalSizeClass {
            case .regular:
                horizontalSizeClass = .regular
            case .compact:
                horizontalSizeClass = .compact
            default:
                break
            }
        }

        if #available(iOS 14.0, *) {
            verticalSizeClass = UserInterfaceSizeClass(traitCollection.verticalSizeClass)
        } else {
            switch traitCollection.verticalSizeClass {
            case .regular:
                verticalSizeClass = .regular
            case .compact:
                verticalSizeClass = .compact
            default:
                break
            }
        }
        #endif
        if #available(iOS 14.0, tvOS 14.0, *), let layoutDirection = LayoutDirection(traitCollection.layoutDirection) {
            self.layoutDirection = layoutDirection
        } else {
            switch traitCollection.layoutDirection {
            case .leftToRight:
                layoutDirection = .leftToRight
            case .rightToLeft:
                layoutDirection = .rightToLeft
            default:
                break
            }
        }
        if #available(iOS 15.0, tvOS 15.0, *), let dynamicTypeSize = DynamicTypeSize(traitCollection.preferredContentSizeCategory) {
            self.dynamicTypeSize = dynamicTypeSize
        } else if #available(iOS 14.0, tvOS 14.0, *), let sizeCategory = ContentSizeCategory(traitCollection.preferredContentSizeCategory) {
            self.sizeCategory = sizeCategory
        } else {
            let sizeCategory: ContentSizeCategory? = {
                switch traitCollection.preferredContentSizeCategory {
                case .extraSmall:
                    return .extraSmall
                case .small:
                    return .small
                case .medium:
                    return .medium
                case .large:
                    return .large
                case .extraLarge:
                    return .extraLarge
                case .extraExtraLarge:
                    return .extraExtraLarge
                case .extraExtraExtraLarge:
                    return .extraExtraExtraLarge
                case .accessibilityMedium:
                    return .accessibilityMedium
                case .accessibilityLarge:
                    return .accessibilityLarge
                case .accessibilityExtraLarge:
                    return .accessibilityExtraLarge
                case .accessibilityExtraExtraLarge:
                    return .accessibilityExtraExtraLarge
                case .accessibilityExtraExtraExtraLarge:
                    return .accessibilityExtraExtraExtraLarge
                default:
                    return nil
                }
            }()
            if let sizeCategory {
                self.sizeCategory = sizeCategory
            }
        }
        if #available(iOS 14.0, tvOS 14.0, *), let colorSchemeContrast = ColorSchemeContrast(traitCollection.accessibilityContrast) {
            self.colorSchemeContrast = colorSchemeContrast
        } else {
            switch traitCollection.accessibilityContrast {
            case .normal:
                colorSchemeContrast = .standard
            case .high:
                colorSchemeContrast = .increased
            default:
                break
            }
        }
        displayScale = traitCollection.displayScale
        if #available(iOS 14.0, tvOS 14.0, *), let legibilityWeight = LegibilityWeight(traitCollection.legibilityWeight) {
            self.legibilityWeight = legibilityWeight
        } else {
            switch traitCollection.legibilityWeight {
            case .regular:
                legibilityWeight = .regular
            case .bold:
                legibilityWeight = .bold
            default:
                break
            }
        }
    }

    /// Returns a copy of the environment values updated with the traits of a `UITraitCollection`.
    public func merging(_ traitCollection: UITraitCollection) -> EnvironmentValues {
        var copy = self
        copy.merge(traitCollection)
        return copy
    }
}
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension OpenURLAction {

    /// The result of performing an `OpenURLAction`.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public enum OpenResult {
        /// The system should open the URL, or a different URL if one is provided.
        case systemAction(URL?, prefersInApp: Bool?)
        /// The handler opened the URL.
        case handled
        /// The handler discarded the URL.
        case discarded

        @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
        enum V7 {
            case systemAction(URL?, prefersInApp: Bool)
            case handled
            case discarded

            var result: OpenResult {
                switch self {
                case .systemAction(let url, let prefersInApp):
                    return .systemAction(url, prefersInApp: prefersInApp)
                case .handled:
                    return .handled
                case .discarded:
                    return .discarded
                }
            }
        }

        enum V3 {
            case systemAction(URL?)
            case handled
            case discarded

            var result: OpenResult {
                switch self {
                case .systemAction(let url):
                    return .systemAction(url, prefersInApp: nil)
                case .handled:
                    return .handled
                case .discarded:
                    return .discarded
                }
            }
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    enum Handler {
        typealias SystemHandler = (URL, @escaping (Bool) -> Void) -> Void
        case system(SystemHandler)
        typealias CustomHandler = (URL) -> OpenURLAction.Result
        case custom(CustomHandler, fallback: SystemHandler?)
    }

    /// Opens a URL, following the user's preferences, and returns the result
    /// of a custom handler if one was provided.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @_disfavoredOverload
    @MainActor @preconcurrency
    public func callAsFunction(_ url: URL) -> OpenResult {
        do {
            let handler = try swift_getFieldValue("handler", Handler.self, self)
            if case .custom(let handler, _) = handler {
                return handler(url).result ?? .handled
            }
        } catch {
            os_log(.debug, log: .default, "Failed to get `handler` with error: %{public}@. Please file an issue.", error.localizedDescription)
        }
        callAsFunction(url)
        return .handled
    }

    /// Opens a URL, following the user's preferences, and returns the result
    /// of a custom handler if one was provided.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @_disfavoredOverload
    @MainActor @preconcurrency
    public func callAsFunction(_ url: URL, prefersInApp: Bool) -> OpenResult {
        do {
            let handler = try swift_getFieldValue("handler", Handler.self, self)
            if case .custom(let handler, _) = handler {
                return handler(url).result ?? .handled
            }
        } catch {
            os_log(.debug, log: .default, "Failed to get `handler` with error: %{public}@. Please file an issue.", error.localizedDescription)
        }
        callAsFunction(url, prefersInApp: prefersInApp)
        return .handled
    }

    /// Whether the action is the default system action.
    public var isDefault: Bool {
        do {
            return try swift_getFieldValue("isDefault", Bool.self, self)
        } catch {
            os_log(.debug, log: .default, "Failed to get `isDefault` with error: %{public}@. Please file an issue.", error.localizedDescription)
            return false
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension OpenURLAction.Result {

    /// The underlying result of the action.
    public var result: OpenURLAction.OpenResult? {
        do {
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                let result = try swift_getFieldValue("actionResult", OpenURLAction.OpenResult.V7.self, self)
                return result.result
            } else {
                let result = try swift_getFieldValue("actionResult", OpenURLAction.OpenResult.V3.self, self)
                return result.result
            }
        } catch {
            os_log(.debug, log: .default, "Failed to get `actionResult` with error: %{public}@. Please file an issue.", error.localizedDescription)
        }
        return nil
    }
}


/// An action that triggers the submission of a view, such as a text field.
@MainActor @preconcurrency
public struct SubmitAction {
    struct Key: EnvironmentKey {
        static let defaultValue: SubmitAction? = nil
    }

    var onSubmit: () -> Void

    /// Triggers the submit action.
    public func callAsFunction() {
        onSubmit()
    }
}

extension View {

    /// Adds an action to perform when the user submits a value to this view.
    ///
    /// A back-port of `onSubmit(of:_:)` for earlier platforms.
    @available(iOS, deprecated: 15.0)
    @available(macOS, deprecated: 12.0)
    @available(tvOS, deprecated: 15.0)
    @available(watchOS, deprecated: 8.0)
    @available(visionOS, deprecated: 1.0)
    @_disfavoredOverload
    public func onSubmit( _ action: @escaping () -> Void) -> some View {
        environment(\.submit, SubmitAction(onSubmit: action))
    }
}

/// A semantic label describing the label of submission within a view hierarchy.
///
/// A back-port of `SubmitLabel` for earlier platforms.
public enum SubmitLabelRole: Sendable {
    struct Key: EnvironmentKey {
        static let defaultValue: SubmitLabelRole? = nil
    }

    /// Defines a submit label with text of "Done".
    case done
    /// Defines a submit label with text of "Go".
    case go
    /// Defines a submit label with text of "Send".
    case send
    /// Defines a submit label with text of "Join".
    case join
    /// Defines a submit label with text of "Route".
    case route
    /// Defines a submit label with text of "Search".
    case search
    /// Defines a submit label with text of "Return".
    case `return`
    /// Defines a submit label with text of "Next".
    case next
    /// Defines a submit label with text of "Continue".
    case `continue`
}

extension View {

    /// Sets the submit label for this view.
    ///
    /// A back-port of `submitLabel(_:)` for earlier platforms.
    @available(iOS, deprecated: 15.0)
    @available(macOS, deprecated: 12.0)
    @available(tvOS, deprecated: 15.0)
    @available(watchOS, deprecated: 8.0)
    @available(visionOS, deprecated: 1.0)
    @_disfavoredOverload
    public func submitRole( _ role: SubmitLabelRole) -> some View {
        environment(\.submitLabelRole, role)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SubmitLabel {

    /// The role of the submit label.
    public var role: SubmitLabelRole? {
        try? swift_getFieldValue("role", SubmitLabelRole.self, self)
    }
}

/// The kind of autocapitalization behavior applied during text input.
///
/// A back-port of `TextInputAutocapitalization` for earlier platforms.
public enum TextInputAutocapitalizationBehaviour: Sendable {
    struct Key: EnvironmentKey {
        static let defaultValue: TextInputAutocapitalizationBehaviour? = nil
    }

    /// Defines an autocapitalizing behavior that will not capitalize anything.
    case never
    /// Defines an autocapitalizing behavior that will capitalize the first letter of every word.
    case words
    /// Defines an autocapitalizing behavior that will capitalize the first letter in every sentence.
    case sentences
    /// Defines an autocapitalizing behavior that will capitalize every letter.
    case characters
}

extension View {

    /// Sets how often the shift key in the keyboard is automatically enabled.
    ///
    /// A back-port of `textInputAutocapitalization(_:)` for earlier platforms.
    @available(iOS, deprecated: 15.0)
    @available(macOS, deprecated: 12.0)
    @available(tvOS, deprecated: 15.0)
    @available(watchOS, deprecated: 8.0)
    @available(visionOS, deprecated: 1.0)
    @_disfavoredOverload
    public func textInputAutocapitalization( _ behaviour: TextInputAutocapitalizationBehaviour) -> some View {
        environment(\.textInputAutocapitalizationBehaviour, behaviour)
    }
}

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension TextInputAutocapitalization {

    /// The behavior of the autocapitalization.
    public var behaviour: TextInputAutocapitalizationBehaviour? {
        try? swift_getFieldValue("behavior", TextInputAutocapitalizationBehaviour.self, self)
    }
}
#endif


#if os(iOS) || os(tvOS) || os(visionOS)
extension UITextAutocapitalizationType {

    /// Creates an autocapitalization type from a `TextInputAutocapitalization`.
    @available(iOS 15.0, tvOS 15.0, *)
    public init?(_ textInputAutocapitalization: TextInputAutocapitalization) {
        guard let behaviour = textInputAutocapitalization.behaviour else { return nil }
        self.init(behaviour)
    }

    /// Creates an autocapitalization type from a ``TextInputAutocapitalizationBehaviour``.
    public init(_ behaviour: TextInputAutocapitalizationBehaviour) {
        switch behaviour {
        case .never:
            self = .none
        case .words:
            self = .words
        case .sentences:
            self = .sentences
        case .characters:
            self = .allCharacters
        }
    }
}

extension UIReturnKeyType {

    /// Creates a return key type from a `SubmitLabel`.
    @available(iOS 15.0, tvOS 15.0, *)
    public init?(_ label: SubmitLabel) {
        guard let role = label.role else { return nil }
        self.init(role)
    }

    /// Creates a return key type from a ``SubmitLabelRole``.
    public init(_ role: SubmitLabelRole) {
        switch role {
        case .done:
            self = .done
        case .go:
            self = .go
        case .send:
            self = .send
        case .join:
            self = .join
        case .route:
            self = .route
        case .search:
            self = .search
        case .return:
            self = .default
        case .next:
            self = .next
        case .continue:
            self = .continue
        }
    }
}
#endif

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct EnvironmentValues_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnvironmentValuePreview(keyPath: \.labelsHidden) {
                TextField("Label", text: .constant(""))
                    .fixedSize()
            } content: { isHidden in
                Text(isHidden.description)
            }
            .labelsHidden()

            HStack {
                EnvironmentValuePreview(keyPath: \.foregroundStyle) {
                    Text("Hello, World")
                } content: { foregroundStyle in
                    Circle()
                        .fill(foregroundStyle)
                        .fixedSize()
                }
                .foregroundStyle(.green)

                EnvironmentValuePreview(keyPath: \.foregroundStyle) {
                    Text("Hello, World")
                } content: { foregroundStyle in
                    Circle()
                        .fill(foregroundStyle)
                        .fixedSize()
                }
                .foregroundStyle(.green)

                EnvironmentValuePreview(keyPath: \.foregroundColor) {
                    Text("Hello, World")
                } content: { foregroundColor in
                    Circle()
                        .fill(foregroundColor ?? .black)
                        .fixedSize()
                }
                .foregroundStyle(.green)
            }

            EnvironmentValuePreview(keyPath: \.tintStyle) {
                Button("Action") { }
            } content: { tintStyle in
                Circle()
                    .fill(tintStyle)
                    .fixedSize()
            }
            .tint(.green)

            HStack {
                EnvironmentValuePreview(keyPath: \.tint) {
                    Button("Action") { }
                } content: { tintColor in
                    Circle()
                        .fill(tintColor ?? .red)
                        .fixedSize()
                }
                .tint(.green)

                EnvironmentValuePreview(keyPath: \.accentColor) {
                    Button("Action") { }
                } content: { accentColor in
                    Circle()
                        .fill(accentColor)
                        .fixedSize()
                }
                .accentColor(.green)
            }

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                EnvironmentValuePreview(keyPath: \.underlineStyle) {
                    Text("Underline")
                } content: { underlineStyle in
                    Text(underlineStyle.debugDescription)
                }
                .underline()

                EnvironmentValuePreview(keyPath: \.strikethroughStyle) {
                    Text("Strikethrough")
                } content: { strikethroughStyle in
                    Text(strikethroughStyle.debugDescription)
                }
                .strikethrough()

                EnvironmentValuePreview(keyPath: \.kerning) {
                    Text("Kerning")
                } content: { kerning in
                    Text(kerning, format: .number)
                }
                .kerning(10)

                EnvironmentValuePreview(keyPath: \.tracking) {
                    Text("Tracking")
                } content: { tracking in
                    Text(tracking, format: .number)
                }
                .tracking(10)

                EnvironmentValuePreview(keyPath: \.baselineOffset) {
                    Text("Baseline Offset")
                } content: { baselineOffset in
                    Text(baselineOffset, format: .number)
                }
                .baselineOffset(10)

                HStack {
                    Text("Line Limit")

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimit) { lineLimit in
                        Text(lineLimit ?? -1, format: .number)
                    }

                    EnvironmentValueReader(\.lineLimitMininum) { lineLimitMininum in
                        Text(lineLimitMininum ?? -1, format: .number)
                    }
                    .lineLimit(2...3)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(2...3)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(2...)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(...3)
                }
            }

            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                EnvironmentValuePreview(keyPath: \.textScale) {
                    Text("Hello, World")
                } content: { textScale in
                    Text(verbatim: "\(textScale)")
                }
                .textScale(.secondary)
            }

            if #available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *) {
                EnvironmentValuePreview(keyPath: \.imageScale) {
                    Image(systemName: "apple.logo")
                } content: { imageScale in
                    Text(verbatim: "\(imageScale.debugDescription)")
                }
                .imageScale(.large)
            }

            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                EnvironmentValuePreview(keyPath: \.textInputAutocapitalizationBehaviour) {
                    TextField("Label", text: .constant(""))
                        .fixedSize()
                } content: { textInputAutocapitalization in
                    Text("\(textInputAutocapitalization.map({ "\($0)" }) ?? "nil")")
                }
                .textInputAutocapitalization(.never)
            }
            #endif

            #if os(iOS) || os(tvOS) || os(visionOS)
            EnvironmentValuePreview(keyPath: \.keyboardType) {
                TextField("Label", text: .constant(""))
                    .fixedSize()

            } content: { keyboardType in
                Text(verbatim: "\(keyboardType)")
            }
            .keyboardType(.numberPad)
            #endif

            #if os(iOS) || os(tvOS) || os(visionOS)
            EnvironmentValuePreview(keyPath: \.textContentType) {
                TextField("Label", text: .constant(""))
                    .fixedSize()
            } content: { textContentType in
                Text(textContentType?.rawValue)
            }
            .textContentType(.name)
            #endif

            EnvironmentValuePreview(keyPath: \.displayCornerRadius) {
                Text("displayCornerRadius")
            } content: { displayCornerRadius in
                Text(displayCornerRadius ?? -1, format: .number)
            }

            EnvironmentValuePreview(keyPath: \.submit) {
                Text("onSubmit")
            } content: { submit in
                EnvironmentValueReader(\.submitLabel) { submitLabel in
                    Button {
                        submit?()
                    } label: {
                        Text(submitLabel?.role.map { String("\($0)") } ?? "default")
                    }
                }
            }
            .submitLabel(.search)
            .onSubmit {
                print("Hello, World")
            }

            EnvironmentValuePreview(keyPath: \.systemColorScheme) {
                Text("systemColorScheme")
                    .foregroundColor(.black)
            } content: { systemColorScheme in
                Text(verbatim: "\(systemColorScheme)")
                    .environment(\.colorScheme, systemColorScheme)
            }
            .environment(\.colorScheme, .dark)

            if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                HStack {
                    EnvironmentValueReader(\.openURL) { openURL in
                        Button {
                            print(openURL)
                            let result: OpenURLAction.OpenResult = openURL(URL(string: "https://apple.com")!)
                            print(result)
                        } label: {
                            Text("Open URL (default)")
                        }
                    }

                    EnvironmentValueReader(\.openURL) { openURL in
                        Button {
                            print(openURL)
                            let result: OpenURLAction.OpenResult = openURL(URL(string: "https://apple.com")!)
                            print(result)
                        } label: {
                            Text("Open URL (handled)")
                        }
                    }
                    .environment(\.openURL, OpenURLAction(handler: { url in
                        return .handled
                    }))

                    EnvironmentValueReader(\.openURL) { openURL in
                        Button {
                            print(openURL)
                            let result: OpenURLAction.OpenResult = openURL(URL(string: "https://apple.com")!)
                            print(result)
                        } label: {
                            Text("Open URL (systemAction)")
                        }
                    }
                    .environment(\.openURL, OpenURLAction(handler: { url in
                        return .systemAction(url)
                    }))

                    EnvironmentValueReader(\.openURL) { openURL in
                        Button {
                            print(openURL)
                            let result: OpenURLAction.OpenResult = openURL(URL(string: "https://apple.com")!)
                            print(result)
                        } label: {
                            Text("Open URL (discarded)")
                        }
                    }
                    .environment(\.openURL, OpenURLAction(handler: { url in
                        return .discarded
                    }))
                }
            }
        }
    }

    struct EnvironmentValuePreview<Value, Source: View, Content: View>: View {

        var keyPath: KeyPath<EnvironmentValues, Value>
        var source: Source
        var content: (Value) -> Content

        init(
            keyPath: KeyPath<EnvironmentValues, Value>,
            @ViewBuilder source: () -> Source,
            @ViewBuilder content: @escaping (Value) -> Content
        ) {
            self.keyPath = keyPath
            self.source = source()
            self.content = content
        }

        var body: some View {
            HStack {
                source

                Divider()
                    .fixedSize()

                EnvironmentValueReader(keyPath) { value in
                    content(value)
                }
            }
        }
    }
}

