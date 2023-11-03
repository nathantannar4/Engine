//
// Copyright (c) Nathan Tannar
//

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
        var type: String
        var isWrapper: Bool
    }
    private static func getProperties(
        members: MemberBlockItemListSyntax
    ) -> [Property] {
        members.compactMap { member -> Property? in
            guard 
                let variable = member.decl.as(VariableDeclSyntax.self),
                let binding = variable.bindings.first,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                let type = variable.type
            else {
                return nil
            }
            return Property(
                name: pattern.identifier.text,
                type: type.text,
                isWrapper: type.isWrapper
            )
        }
    }

    private static func makeInit(
        name: String,
        prefix: String,
        subviews: Set<String>,
        properties: [Property]
    ) -> String {
        let initArgs = properties.map { property in
            if subviews.contains(property.type) {
                return "@ViewBuilder \(property.name): () -> \(property.type)"
            } else {
                return "\(property.name): \(property.type)"
            }
        }
        let initProperties = properties.map { property in
            if subviews.contains(property.type) {
                return "self.\(property.name) = \(property.name)()"
            } else {
                return "self.\(property.isWrapper ? "_" : "")\(property.name) = \(property.name)"
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
            "self.\(property.isWrapper ? "_" : "")\(property.name) = configuration.\(property.name)"
        }
        let whereClause = properties.compactMap { property -> String? in
            guard subviews.contains(property.type) else {
                return nil
            }
            return "\(property.type) == \(name)Configuration.\(property.type)"
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
            guard !subviews.contains(property.type) else {
                return nil
            }
            return "\(property.name): \(property.isWrapper ? "$" : "")\(property.name)"
        }
        let modifiers = properties.compactMap { property -> String? in
            guard subviews.contains(property.type) else {
                return nil
            }
            return ".viewAlias(\(name)Configuration.\(property.type).self) { \(property.name) }"
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
            if subviews.contains(property.type) {
                return [
                    "\(prefix)struct \(property.type): ViewAlias { }",
                    "\(prefix)var \(property.name): \(property.type) { .init() }"
                ]

            } else {
                return [
                    "\(prefix)var \(property.name): \(property.type)"
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
            associatedtype Configuration = Configuration
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

extension VariableDeclSyntax {
    var type: (text: String, isWrapper: Bool)? {
        guard
            let binding = bindings.first,
            let typeAnnotation = binding.typeAnnotation?.as(TypeAnnotationSyntax.self),
            let type = typeAnnotation.type.as(IdentifierTypeSyntax.self)
        else {
            return nil
        }
        if attributes.isEmpty {
            return (type.text, false)
        }
        let attributes = attributes
            .compactMap { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self) }
            .map { $0.text }
        let result = attributes.reduce(into: type.text) { result, attribute in
            result = "\(attribute)<\(result)>"
        }
        return (result, true)
    }
}

extension IdentifierTypeSyntax {
    var text: String {
        var text = name.text
        if let genericArgumentClause {
            let generics = genericArgumentClause.arguments
                .compactMap { $0.as(GenericArgumentSyntax.self)?.argument }
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
