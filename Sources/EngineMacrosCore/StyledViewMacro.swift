//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        let type = try getType(
            declaration: declaration
        )
        let name = type.name.text
        let prefix = getPrefix(
            modifiers: type.modifiers
        )
        let generics = type.genericParameterClause
        let members = type.memberBlock.members
        let subviews = getSubviews(
            members: members,
            generics: generics
        )
        let properties = getProperties(
            members: members
        )
        return [
            DeclSyntax(
                stringLiteral: makeBody(
                    name: name,
                    prefix: prefix,
                    subviews: subviews,
                    properties: properties
                )
            ),
            DeclSyntax(
                stringLiteral: makeInit(
                    name: name,
                    prefix: prefix,
                    subviews: subviews,
                    properties: properties
                )
            ),
            DeclSyntax(
                stringLiteral: makeConfigurationInit(
                    name: name,
                    prefix: prefix,
                    subviews: subviews,
                    properties: properties
                )
            )
        ]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let type = try getType(
            declaration: declaration
        )
        let name = type.name.text
        let prefix = getPrefix(
            modifiers: type.modifiers
        )
        let generics = type.genericParameterClause
        let members = type.memberBlock.members
        let subviews = getSubviews(
            members: members,
            generics: generics
        )
        let properties = getProperties(
            members: members
        )
        return [
            DeclSyntax(
                stringLiteral: makeConfigurationStruct(
                    name: name,
                    prefix: prefix,
                    subviews: subviews,
                    properties: properties
                )
            ),
            DeclSyntax(
                stringLiteral: makeStyleProtocol(
                    name: name,
                    prefix: prefix
                )
            ),
            DeclSyntax(
                stringLiteral: makeDefaultStyle(
                    name: name,
                    prefix: prefix
                )
            ),
            DeclSyntax(
                stringLiteral: makeViewStyledView(
                    name: name
                )
            ),
            DeclSyntax(
                stringLiteral: makeStyleModifier(
                    name: name,
                    prefix: prefix
                )
            )
        ]
    }

    private static func getType(
        declaration: some SyntaxProtocol
    ) throws -> StructDeclSyntax {
        guard let type = declaration.as(StructDeclSyntax.self) else {
            throw Error.unsupportedType
        }
        guard
            let inheritanceClause = type.inheritanceClause,
            inheritanceClause.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.text == "StyledView" })
        else {
            throw Error.missingConformance
        }
        return type
    }

    private static let knownVisibilityKeywords: Set<String> = ["public", "open", "private", "fileprivate", "internal"]

    private static func getPrefix(
        modifiers: DeclModifierListSyntax
    ) -> String {
        let visibility = modifiers.lazy
            .compactMap { modifier in
                let name = modifier.name.text
                return knownVisibilityKeywords.contains(name) ? name : nil
            }
            .first
        guard let visibility else {
            return ""
        }
        return "\(visibility) "
    }

    private static func getSubviews(
        members: MemberBlockItemListSyntax,
        generics: GenericParameterClauseSyntax?
    ) -> Set<String> {
        guard let generics else {
            return []
        }
        let views = generics.parameters.filter {
            guard let type = $0.inheritedType else {
                return false
            }
            return type.as(IdentifierTypeSyntax.self)?.name.text == "View"
        }
        return Set(views.map { $0.name.text })
    }

    private struct Property {
        var name: String
        var field: SyntaxField
    }
    private static func getProperties(
        members: MemberBlockItemListSyntax
    ) -> [Property] {
        members.compactMap { member -> Property? in
            guard 
                let variable = member.decl.as(VariableDeclSyntax.self),
                variable.bindings.count == 1,
                let binding = variable.bindings.first,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                let field = variable.field
            else {
                return nil
            }
            return Property(
                name: identifier.identifier.text,
                field: field
            )
        }
    }

    private static func makeInit(
        name: String,
        prefix: String,
        subviews: Set<String>,
        properties: [Property]
    ) -> String {
        let initArgs = properties
            .sorted { lhs, rhs in
                return !lhs.field.isFunction && rhs.field.isFunction
            }
            .sorted { lhs, rhs in
                return !subviews.contains(lhs.field.type) && subviews.contains(rhs.field.type)
            }
            .map { property in
                if subviews.contains(property.field.type) {
                    return "@ViewBuilder \(property.name): () -> \(property.field.type)"
                } else {
                    return "\(property.name): \(property.field.isFunction && !property.field.isOptional ? "@escaping " : "")\(property.field.attributedType)\(property.field.isOptional ? " = nil" : "")"
                }
            }
        let initProperties = properties.map { property in
            if subviews.contains(property.field.type) {
                return "self.\(property.name) = \(property.name)()"
            } else {
                return "self.\(property.field.attributes.isEmpty ? "" : "_")\(property.name) = \(property.name)"
            }
        }
        return """
        \(prefix)init(
            \(initArgs.joined(separator: ",\n"))
        ) {
            \(initProperties.joined(separator: "\n"))
        }
        """
    }

    private static func makeConfigurationInit(
        name: String,
        prefix: String,
        subviews: Set<String>,
        properties: [Property]
    ) -> String {
        let initProperties = properties.map { property in
            "self.\(property.field.attributes.isEmpty ? "" : "_")\(property.name) = configuration.\(property.field.attributes.isEmpty ? "" : "$")\(property.name)"
        }
        let whereClause = properties.compactMap { property -> String? in
            guard subviews.contains(property.field.type) else {
                return nil
            }
            return "\(property.field.type) == \(name)Configuration.\(property.field.type)"
        }.joined(separator: ", ")
        return """
        \(prefix)init(
            _ configuration: \(name)Configuration
        ) \(whereClause.isEmpty ? "" : "where") \(whereClause) {
            \(initProperties.joined(separator: "\n"))
        }
        """
    }

    private static func makeBody(
        name: String,
        prefix: String,
        subviews: Set<String>,
        properties: [Property]
    ) -> String {
        let params = properties.compactMap { property -> String? in
            guard !subviews.contains(property.field.type) else {
                return nil
            }
            return "\(property.name): \(property.field.attributes.isEmpty ? "" : "$")\(property.name)"
        }
        let modifiers = properties.compactMap { property -> String? in
            guard subviews.contains(property.field.type) else {
                return nil
            }
            return ".viewAlias(\(name)Configuration.\(property.field.type).self) { \(property.name) }"
        }
        return """
        \(prefix)var _body: some View {
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
        name: String,
        prefix: String,
        subviews: Set<String>,
        properties: [Property]
    ) -> String {
        let fields = properties.flatMap { property in
            if subviews.contains(property.field.type) {
                return [
                    "\(prefix)struct \(property.field.type): ViewAlias { }",
                    "\(prefix)var \(property.name): \(property.field.type) { .init() }"
                ]

            } else {
                return [
                    "\(property.field.attributes.map({ "@\($0) " }).joined())\(prefix)var \(property.name): \(property.field.type)"
                ]
            }
        }
        return """
        \(prefix)struct \(name)Configuration {
            \(fields.joined(separator: "\n"))
        }
        """
    }

    private static func makeStyleProtocol(
        name: String,
        prefix: String
    ) -> String {
        return """
        \(prefix)protocol \(name)Style: ViewStyle where Configuration == \(name)Configuration {
        }
        """
    }

    private static func makeDefaultStyle(
        name: String,
        prefix: String
    ) -> String {
        return """
        \(prefix)struct \(name)DefaultStyle: \(name)Style {
            \(prefix)func makeBody(configuration: \(name)Configuration) -> some View {
                _DefaultStyledView(\(name)(configuration))
            }
        }
        """
    }

    private static func makeViewStyledView(
        name: String
    ) -> String {
        return """
        private struct \(name)Body: ViewStyledView {
            var configuration: \(name)Configuration

            static var defaultStyle: \(name)DefaultStyle {
                \(name)DefaultStyle()
            }
        }
        """
    }

    private static func makeStyleModifier(
        name: String,
        prefix: String
    ) -> String {
        return """
        \(prefix)struct \(name)StyleModifier<Style: \(name)Style>: ViewModifier {
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

    public enum Error: Swift.Error, CustomStringConvertible {
        case unsupportedType
        case missingConformance

        public var description: String {
            switch self {
            case .unsupportedType:
                return "StyledViewMacro can only be applied to a struct"
            case .missingConformance:
                return "StyledViewMacro must be used on a type that conforms to `StyledView`"
            }
        }
    }
}

struct SyntaxField {
    var type: String
    var attributes: [String]
    var isFunction: Bool
    var isOptional: Bool

    var attributedType: String {
        attributes.reduce(into: type) { result, attribute in
            result = "\(attribute)<\(result)>"
        }
    }
}

extension VariableDeclSyntax {
    var field: SyntaxField? {
        guard
            let binding = bindings.first,
            let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }
        switch typeAnnotation.type.kind {
        case .identifierType:
            let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if attributes.isEmpty {
                return SyntaxField(type: type, attributes: [], isFunction: false, isOptional: false)
            }
            let attributes = attributes
                .compactMap { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self) }
                .map { $0.text }
            return SyntaxField(type: type, attributes: attributes, isFunction: false, isOptional: false)

        case .optionalType:
            let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let isFunction = {
                guard let wrappedType = typeAnnotation.type.as(OptionalTypeSyntax.self)?.wrappedType else {
                    return false
                }
                switch wrappedType.kind {
                case .tupleType:
                    guard let tupleType = wrappedType.as(TupleTypeSyntax.self), tupleType.elements.count == 1 else { return false }
                    return tupleType.elements.first?.type.kind == .functionType

                case .functionType:
                    return true

                default:
                    return false
                }
            }()
            return SyntaxField(type: type, attributes: [], isFunction: isFunction, isOptional: true)

        case .functionType:
            let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
            return SyntaxField(type: type, attributes: [], isFunction: true, isOptional: false)

        default:
            return nil
        }
    }
}

extension FunctionTypeSyntax {

}

extension IdentifierTypeSyntax {
    var text: String {
        var text = name.text
        if let genericArgumentClause {
            let generics = genericArgumentClause.arguments
                .compactMap { $0.argument }
                .compactMap { $0.as(IdentifierTypeSyntax.self) }
                .map { $0.text }
            text += "<\(generics.joined(separator: ", "))>"
        }
        return text
    }
}

extension String {
    var asFunctionName: String {
        prefix(1).lowercased() + dropFirst()
    }
}
