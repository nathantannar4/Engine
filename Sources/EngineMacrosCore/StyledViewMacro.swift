//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The implementation of the `@StyledView` macro.
public struct StyledViewMacro: PeerMacro, MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try expansion(
            of: node,
            providingMembersOf: declaration,
            conformingTo: [],
            in: context
        )
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Diagnostics are only emitted by the member expansion, so they are not duplicated
        guard let view = makeStyledView(of: node, declaration: declaration, in: context, diagnose: true) else {
            return []
        }
        var declarations = [DeclSyntax]()
        declarations.append(
            DeclSyntax(
                stringLiteral: makeBody(
                    view: view
                )
            )
        )
        declarations.append(
            DeclSyntax(
                stringLiteral: makeInit(
                    view: view,
                    isViewBuilder: true
                )
            )
        )
        if !view.subviews.isEmpty {
            declarations.append(
                DeclSyntax(
                    stringLiteral: makeInit(
                        view: view,
                        isViewBuilder: false
                    )
                )
            )
        }
        declarations.append(
            DeclSyntax(
                stringLiteral: makeConfigurationInit(
                    view: view
                )
            )
        )
        declarations.append(
            DeclSyntax(
                stringLiteral: makeConfigurationTypealias(
                    view: view
                )
            )
        )
        return declarations
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let view = makeStyledView(of: node, declaration: declaration, in: context, diagnose: false) else {
            return []
        }
        let declarations = [
            DeclSyntax(
                stringLiteral: makeStyledTypealias(
                    view: view
                )
            ),
            DeclSyntax(
                stringLiteral: makeConfigurationStruct(
                    view: view
                )
            ),
            DeclSyntax(
                stringLiteral: makeStyleProtocol(
                    view: view
                )
            ),
            DeclSyntax(
                stringLiteral: makeDefaultStyle(
                    view: view
                )
            ),
            DeclSyntax(
                stringLiteral: makeViewStyledView(
                    view: view
                )
            ),
            DeclSyntax(
                stringLiteral: makeStyleModifier(
                    view: view
                )
            )
        ]
        return declarations
    }

    // MARK: - Model

    private struct StyledView {
        var name: String
        /// The access modifier of the generated peer types
        var typePrefix: String
        /// The access modifier of the generated members, which must be visible outside their type
        var memberPrefix: String
        /// The generic parameters constrained to `View`, in declaration order
        var subviews: [String]
        var properties: [Property]
    }

    private struct Property {
        enum Kind {
            /// A property whose type is one of the generic `View` parameters
            case subview
            /// A `@Binding` property, passed to the configuration as a binding
            case binding
            case value
        }

        var name: String
        var type: TypeSyntax
        var kind: Kind
        var defaultValue: String?

        var typeName: String {
            type.trimmedDescription
        }

        var isOptional: Bool {
            StyledViewMacro.isOptional(type)
        }

        var isFunction: Bool {
            StyledViewMacro.isFunction(type)
        }

        /// Whether the property is a function or an optional function
        var isClosure: Bool {
            let type = StyledViewMacro.unwrapped(type)
            if let optional = type.as(OptionalTypeSyntax.self) {
                return StyledViewMacro.isFunction(optional.wrappedType)
            }
            return StyledViewMacro.isFunction(type)
        }
    }

    private static func makeStyledView(
        of node: AttributeSyntax,
        declaration: some SyntaxProtocol,
        in context: some MacroExpansionContext,
        diagnose isDiagnosing: Bool
    ) -> StyledView? {
        func diagnose(_ error: Error, node: some SyntaxProtocol) {
            if isDiagnosing {
                context.diagnose(Diagnostic(node: node, message: error))
            }
        }

        guard let type = declaration.as(StructDeclSyntax.self) else {
            diagnose(.unsupportedType, node: node)
            return nil
        }
        guard
            let inheritanceClause = type.inheritanceClause,
            inheritanceClause.inheritedTypes.contains(where: { isStyledViewType($0.type) })
        else {
            diagnose(.missingConformance, node: node)
            return nil
        }

        let subviews = getSubviews(of: type)
        if let generics = type.genericParameterClause {
            for parameter in generics.parameters where !subviews.contains(parameter.name.text) {
                diagnose(.unsupportedGenericParameter, node: parameter)
                return nil
            }
        }

        var properties = [Property]()
        var subviewProperties = Set<String>()
        for (binding, propertyType, variable) in getStoredProperties(of: type) {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            let wrappers = getPropertyWrappers(of: variable)
            let isBinding = wrappers.contains { $0.attributeName.trimmedDescription.split(separator: ".").last == "Binding" }

            // Properties that initialize themselves, such as `@State var value = 0` or
            // `@Environment(\.colorScheme) var colorScheme`, are not part of the configuration
            if !isBinding, !wrappers.isEmpty,
                binding.initializer != nil || wrappers.contains(where: { $0.arguments != nil })
            {
                continue
            }
            if variable.bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
                continue
            }
            guard let propertyType else {
                continue
            }

            let kind: Property.Kind
            if let identifierType = propertyType.as(IdentifierTypeSyntax.self),
                subviews.contains(identifierType.name.text)
            {
                guard subviewProperties.insert(identifierType.name.text).inserted else {
                    diagnose(.duplicateSubview, node: binding)
                    return nil
                }
                kind = .subview
            } else if references(propertyType, anyOf: subviews) {
                diagnose(.unsupportedSubviewType, node: binding)
                return nil
            } else {
                kind = isBinding ? .binding : .value
            }

            properties.append(
                Property(
                    name: identifier.identifier.text,
                    type: propertyType,
                    kind: kind,
                    defaultValue: isBinding ? nil : binding.initializer?.value.trimmedDescription
                )
            )
        }

        let visibility = getVisibility(modifiers: type.modifiers)
        return StyledView(
            name: type.name.text,
            typePrefix: visibility.map { "\($0) " } ?? "",
            // A `private` member of a `private` type is only visible within the type
            memberPrefix: visibility.map { $0 == "private" ? "fileprivate " : "\($0) " } ?? "",
            subviews: subviews,
            properties: properties
        )
    }

    private static func isStyledViewType(_ type: TypeSyntax) -> Bool {
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "StyledView"
        }
        if let member = type.as(MemberTypeSyntax.self) {
            return member.name.text == "StyledView"
        }
        return false
    }

    private static func isViewType(_ type: TypeSyntax) -> Bool {
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "View"
        }
        if let member = type.as(MemberTypeSyntax.self) {
            return member.baseType.trimmedDescription == "SwiftUI" && member.name.text == "View"
        }
        return false
    }

    private static let knownVisibilityKeywords: Set<String> = ["public", "package", "internal", "fileprivate", "private"]

    private static func getVisibility(
        modifiers: DeclModifierListSyntax
    ) -> String? {
        modifiers.lazy
            .map { $0.name.text }
            .first { knownVisibilityKeywords.contains($0) }
    }

    private static func getSubviews(
        of type: StructDeclSyntax
    ) -> [String] {
        guard let generics = type.genericParameterClause else {
            return []
        }
        var views = Set<String>()
        for parameter in generics.parameters {
            if let inheritedType = parameter.inheritedType, isViewType(inheritedType) {
                views.insert(parameter.name.text)
            }
        }
        for requirement in type.genericWhereClause?.requirements ?? [] {
            if case .conformanceRequirement(let conformance) = requirement.requirement,
                let identifier = conformance.leftType.as(IdentifierTypeSyntax.self),
                isViewType(conformance.rightType)
            {
                views.insert(identifier.name.text)
            }
        }
        return generics.parameters
            .map { $0.name.text }
            .filter { views.contains($0) }
    }

    /// The stored instance properties, along with their type. The type is inherited from
    /// a later binding when omitted, such as `var a, b: Int`.
    private static func getStoredProperties(
        of type: StructDeclSyntax
    ) -> [(PatternBindingSyntax, TypeSyntax?, VariableDeclSyntax)] {
        type.memberBlock.members.flatMap { member -> [(PatternBindingSyntax, TypeSyntax?, VariableDeclSyntax)] in
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                !variable.modifiers.contains(where: {
                    ["static", "class", "lazy"].contains($0.name.text)
                })
            else {
                return []
            }
            var propertyType: TypeSyntax?
            var properties: [(PatternBindingSyntax, TypeSyntax?, VariableDeclSyntax)] = []
            for binding in variable.bindings.reversed() {
                if let type = binding.typeAnnotation?.type {
                    propertyType = type
                } else if binding.initializer != nil {
                    propertyType = nil
                }
                guard !isComputed(binding) else {
                    continue
                }
                properties.insert((binding, propertyType, variable), at: 0)
            }
            return properties
        }
    }

    private static func isComputed(_ binding: PatternBindingSyntax) -> Bool {
        switch binding.accessorBlock?.accessors {
        case .none:
            return false
        case .getter:
            return true
        case .accessors(let accessors):
            // Properties with only observers are stored
            return accessors.contains {
                !["willSet", "didSet"].contains($0.accessorSpecifier.text)
            }
        }
    }

    /// The property wrappers of a variable, ignoring attributes such as `@available`.
    private static func getPropertyWrappers(
        of variable: VariableDeclSyntax
    ) -> [AttributeSyntax] {
        variable.attributes.compactMap { attribute in
            guard
                let attribute = attribute.as(AttributeSyntax.self),
                let name = attribute.attributeName.trimmedDescription.split(separator: ".").last,
                name.first?.isUppercase == true,
                !knownAttributes.contains(String(name))
            else {
                return nil
            }
            return attribute
        }
    }

    /// Uppercased attributes that are not property wrappers
    private static let knownAttributes: Set<String> = ["MainActor"]

    private static func references(_ type: TypeSyntax, anyOf names: [String]) -> Bool {
        type.tokens(viewMode: .sourceAccurate).contains { token in
            if case .identifier(let text) = token.tokenKind {
                return names.contains(text)
            }
            return false
        }
    }

    private static func unwrapped(_ type: TypeSyntax) -> TypeSyntax {
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return unwrapped(attributed.baseType)
        }
        if let tuple = type.as(TupleTypeSyntax.self),
            tuple.elements.count == 1,
            let element = tuple.elements.first,
            element.firstName == nil
        {
            return unwrapped(element.type)
        }
        return type
    }

    private static func isFunction(_ type: TypeSyntax) -> Bool {
        unwrapped(type).is(FunctionTypeSyntax.self)
    }

    private static func isOptional(_ type: TypeSyntax) -> Bool {
        let type = unwrapped(type)
        if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return true
        }
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "Optional" && identifier.genericArgumentClause != nil
        }
        if let member = type.as(MemberTypeSyntax.self) {
            return member.baseType.trimmedDescription == "Swift"
                && member.name.text == "Optional"
                && member.genericArgumentClause != nil
        }
        return false
    }

    // MARK: - Code Generation

    private static func makeInit(
        view: StyledView,
        isViewBuilder: Bool
    ) -> String {
        func rank(_ property: Property) -> Int {
            switch property.kind {
            case .subview:
                return isViewBuilder ? 2 : 0
            case .binding, .value:
                return property.isClosure ? 1 : 0
            }
        }
        // Trailing closures are last, with view builders after any other closures
        let initArgs = view.properties
            .enumerated()
            .sorted { lhs, rhs in
                (rank(lhs.element), lhs.offset) < (rank(rhs.element), rhs.offset)
            }
            .map { _, property in
                switch property.kind {
                case .subview where isViewBuilder:
                    return "@ViewBuilder \(property.name): () -> \(property.typeName)"
                case .subview:
                    return "\(property.name): \(property.typeName)"
                case .binding:
                    return "\(property.name): Binding<\(property.typeName)>"
                case .value:
                    let escaping = property.isFunction && !property.isOptional ? "@escaping " : ""
                    let defaultValue = property.defaultValue ?? (property.isOptional ? "nil" : nil)
                    return "\(property.name): \(escaping)\(property.typeName)\(defaultValue.map { " = \($0)" } ?? "")"
                }
            }
        let initProperties = view.properties.map { property in
            switch property.kind {
            case .subview where isViewBuilder:
                return "self.\(property.name) = \(property.name)()"
            case .binding:
                return "self._\(property.name) = \(property.name)"
            case .subview, .value:
                return "self.\(property.name) = \(property.name)"
            }
        }
        return """
        \(view.memberPrefix)init(
            \(initArgs.joined(separator: ",\n"))
        ) {
            \(initProperties.joined(separator: "\n"))
        }
        """
    }

    private static func makeConfigurationInit(
        view: StyledView
    ) -> String {
        let initProperties = view.properties.map { property in
            switch property.kind {
            case .binding:
                return "self._\(property.name) = configuration.$\(property.name)"
            case .subview, .value:
                return "self.\(property.name) = configuration.\(property.name)"
            }
        }
        let whereClause = view.subviews.map { subview in
            "\(subview) == \(view.name)Configuration.\(subview)"
        }.joined(separator: ", ")
        return """
        \(view.memberPrefix)init(
            _ configuration: \(view.name)Configuration
        ) \(whereClause.isEmpty ? "" : "where") \(whereClause) {
            \(initProperties.joined(separator: "\n"))
        }
        """
    }

    private static func makeBody(
        view: StyledView
    ) -> String {
        let name = view.name
        let params = view.properties.compactMap { property -> String? in
            switch property.kind {
            case .subview:
                return nil
            case .binding:
                return "\(property.name): $\(property.name)"
            case .value:
                return "\(property.name): \(property.name)"
            }
        }
        let modifiers = view.properties.compactMap { property -> String? in
            guard property.kind == .subview else {
                return nil
            }
            return ".viewAlias(\(name)Configuration.\(property.typeName).self) { \(property.name) }"
        }
        if params.isEmpty {
            return """
            \(view.memberPrefix)var _body: some View {
                \(name)Body(
                    configuration: \(name)Configuration()
                )
                \(modifiers.joined(separator: "\n"))
            }
            """
        }
        return """
        \(view.memberPrefix)var _body: some View {
            \(name)Body(
                configuration: \(name)Configuration(
                    \(params.joined(separator: ",\n"))
                )
            )
            \(modifiers.joined(separator: "\n"))
        }
        """
    }

    private static func makeConfigurationStruct(
        view: StyledView
    ) -> String {
        let prefix = view.memberPrefix
        var aliases = Set<String>()
        func makeAlias(_ subview: String) -> [String] {
            guard aliases.insert(subview).inserted else {
                return []
            }
            return ["\(prefix)struct \(subview): ViewAlias { }"]
        }
        var fields = view.properties.flatMap { property in
            switch property.kind {
            case .subview:
                return makeAlias(property.typeName) + [
                    "\(prefix)var \(property.name): \(property.typeName) { .init() }"
                ]
            case .binding:
                return ["@Binding \(prefix)var \(property.name): \(property.typeName)"]
            case .value:
                return ["\(prefix)var \(property.name): \(property.typeName)"]
            }
        }
        // The `Styled<Name>` typealias references an alias for every generic view parameter
        fields += view.subviews.flatMap(makeAlias)
        return """
        \(view.typePrefix)struct \(view.name)Configuration {
            \(fields.joined(separator: "\n"))
        }
        """
    }

    private static func makeConfigurationTypealias(
        view: StyledView
    ) -> String {
        return """
        \(view.memberPrefix)typealias Configuration = \(view.name)Configuration
        """
    }

    private static func makeStyledTypealias(
        view: StyledView
    ) -> String {
        let name = view.name
        if view.subviews.isEmpty {
            return """
            \(view.typePrefix)typealias Styled\(name) = \(name)
            """
        }
        let configuration = "\(name)Configuration"
        let subviews = view.subviews.map { "\(configuration).\($0)"}
        return """
        \(view.typePrefix)typealias Styled\(name) = \(name)<\(subviews.joined(separator: ", "))>
        """
    }

    private static func makeStyleProtocol(
        view: StyledView
    ) -> String {
        return """
        \(view.typePrefix)protocol \(view.name)Style: ViewStyle where Configuration == \(view.name)Configuration {
        }
        """
    }

    private static func makeDefaultStyle(
        view: StyledView
    ) -> String {
        let name = view.name
        return """
        \(view.typePrefix)struct \(name)DefaultStyle: \(name)Style {
            \(view.memberPrefix)func makeBody(configuration: \(name)Configuration) -> some View {
                _DefaultStyledView<Styled\(name)>(configuration)
            }
        }
        """
    }

    private static func makeViewStyledView(
        view: StyledView
    ) -> String {
        let name = view.name
        return """
        private struct \(name)Body: ViewStyledView {
            var configuration: \(name)Configuration

            var body: some View {
                Styled\(name).makeResolvedStyleBody(configuration: configuration)
            }

            static var defaultStyle: \(name)DefaultStyle {
                \(name)DefaultStyle()
            }
        }
        """
    }

    private static func makeStyleModifier(
        view: StyledView
    ) -> String {
        let name = view.name
        let prefix = view.memberPrefix
        return """
        \(view.typePrefix)struct \(name)StyleModifier<Style: \(name)Style>: ViewModifier {
            \(prefix)var style: Style

            \(prefix)init(_ style: Style) {
                self.style = style
            }

            \(prefix)func body(content: Content) -> some View {
                content.styledViewStyle(\(name)Body.self, style: style)
            }
        }
        """
    }

    // MARK: - Diagnostics

    /// The diagnostics emitted by the `@StyledView` macro.
    public enum Error: String, Swift.Error, CustomStringConvertible, DiagnosticMessage {
        case unsupportedType
        case missingConformance
        case unsupportedGenericParameter
        case duplicateSubview
        case unsupportedSubviewType

        public var message: String {
            return description
        }

        public var diagnosticID: MessageID {
            return MessageID(domain: "StyledViewMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity {
            return .error
        }

        public var description: String {
            switch self {
            case .unsupportedType:
                return "StyledViewMacro can only be applied to a struct"
            case .missingConformance:
                return "StyledViewMacro must be used on a type that conforms to `StyledView`"
            case .unsupportedGenericParameter:
                return "StyledViewMacro only supports generic parameters that conform to `View`"
            case .duplicateSubview:
                return "StyledViewMacro requires each generic `View` parameter to be used by only one property"
            case .unsupportedSubviewType:
                return "StyledViewMacro requires a generic `View` parameter to be used directly as the type of a property"
            }
        }
    }
}
