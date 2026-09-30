//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The implementation of the `@Union` macro.
public struct UnionMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let declaration = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: Error.unsupportedType
            ))
            return []
        }

        let items = collectCases(from: declaration.memberBlock.members)
        let cases = items.flatMap { $0.cases }

        let prefix = getPrefix(
            modifiers: declaration.modifiers
        )

        var names = NameRegistry(
            declared: declaredNames(in: declaration.memberBlock.members),
            taken: Set(
                cases
                    .filter { $0.element.parameterClause == nil }
                    .map { $0.element.name.text.unescaped }
            )
        )

        var declarations: [DeclSyntax] = []

        if cases.contains(where: { $0.element.parameterClause != nil }),
            names.claim(["CaseKey", "key"], node: node, in: context)
        {
            declarations.append(
                DeclSyntax(
                    stringLiteral: makeCaseKeyEnum(
                        items: items,
                        prefix: prefix
                    )
                )
            )

            declarations.append(
                DeclSyntax(
                    stringLiteral: makeCaseKeyAccessor(
                        items: items,
                        prefix: prefix
                    )
                )
            )
        }

        // Claim the `is<Case>` and case named accessors before the per field
        // accessors, so that a field accessor never shadows a case accessor.
        var plans: [SyntaxIdentifier: Plan] = [:]
        walk(items, names: &names) { unionCase, names in
            let element = unionCase.element
            var plan = Plan(fields: makeFields(for: element))
            let isName = "is\(element.name.text.unescaped.uppercasedFirst)"
            if names.claim([isName], node: element, in: context) {
                plan.isAccessor = isName
            }
            if let valueName = plan.valueAccessorName(for: element),
                names.claim([valueName], node: element, in: context)
            {
                plan.valueAccessor = valueName
            }
            plans[element.id] = plan
        }
        walk(items, names: &names) { unionCase, names in
            let element = unionCase.element
            guard plans[element.id]!.fields.count > 1 else { return }
            for field in plans[element.id]!.fields {
                if names.claim([field.accessorName], node: element, in: context) {
                    plans[element.id]!.fieldAccessors.insert(field.index)
                }
            }
        }

        let accessors = emit(items, separator: "\n\n") { unionCase in
            makeAccessors(
                for: unionCase,
                plan: plans[unionCase.element.id]!,
                prefix: prefix
            )
        }
        declarations.append(
            contentsOf: accessors.map { DeclSyntax(stringLiteral: $0) }
        )
        return declarations
    }

    // MARK: - Cases

    private struct Case {
        var element: EnumCaseElementSyntax
        var attributes: [String]
    }

    private indirect enum CaseItem {
        case `case`(Case)
        case ifConfig([(header: String, items: [CaseItem])])

        var cases: [Case] {
            switch self {
            case .case(let unionCase):
                return [unionCase]
            case .ifConfig(let clauses):
                return clauses.flatMap { $0.items.flatMap { $0.cases } }
            }
        }
    }

    private static func collectCases(
        from members: MemberBlockItemListSyntax
    ) -> [CaseItem] {
        members.flatMap { member -> [CaseItem] in
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                let attributes = caseDecl.attributes.compactMap { attribute -> String? in
                    guard
                        let attribute = attribute.as(AttributeSyntax.self),
                        attribute.attributeName.trimmedDescription == "available"
                    else {
                        return nil
                    }
                    return attribute.trimmedDescription
                }
                return caseDecl.elements.map {
                    .case(Case(element: $0, attributes: attributes))
                }
            }
            if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
                let clauses = ifConfig.clauses.map { clause in
                    var header = clause.poundKeyword.text
                    if let condition = clause.condition {
                        header += " \(condition.trimmedDescription)"
                    }
                    var items: [CaseItem] = []
                    if case .decls(let decls) = clause.elements {
                        items = collectCases(from: decls)
                    }
                    return (header: header, items: items)
                }
                guard clauses.contains(where: { !$0.items.isEmpty }) else {
                    return []
                }
                return [.ifConfig(clauses)]
            }
            return []
        }
    }

    /// Generates code for each case, preserving any `#if` blocks the cases are declared in.
    private static func emit(
        _ items: [CaseItem],
        separator: String,
        transform: (Case) -> [String]
    ) -> [String] {
        items.flatMap { item -> [String] in
            switch item {
            case .case(let unionCase):
                return transform(unionCase)
            case .ifConfig(let clauses):
                let bodies = clauses.map {
                    emit($0.items, separator: separator, transform: transform)
                }
                guard bodies.contains(where: { !$0.isEmpty }) else {
                    return []
                }
                let text = zip(clauses, bodies).map { clause, body in
                    body.isEmpty ? clause.header : "\(clause.header)\n\(body.joined(separator: separator))"
                }
                return [(text + ["#endif"]).joined(separator: "\n")]
            }
        }
    }

    // MARK: - Names

    private struct NameRegistry {
        /// Names declared by the user, generation of these is silently skipped.
        var declared: Set<String>
        /// Names already used by a case or another generated member.
        var taken: Set<String>

        mutating func claim(
            _ names: [String],
            node: some SyntaxProtocol,
            in context: some MacroExpansionContext
        ) -> Bool {
            let names = names.map { $0.unescaped }
            if names.contains(where: { declared.contains($0) }) {
                return false
            }
            if let collision = names.first(where: { taken.contains($0) }) {
                context.diagnose(Diagnostic(
                    node: node,
                    message: NameCollision(name: collision)
                ))
                return false
            }
            taken.formUnion(names)
            return true
        }
    }

    /// Visits each case, where the cases in sibling `#if` clauses do not conflict with each other.
    private static func walk(
        _ items: [CaseItem],
        names: inout NameRegistry,
        _ body: (Case, inout NameRegistry) -> Void
    ) {
        for item in items {
            switch item {
            case .case(let unionCase):
                body(unionCase, &names)
            case .ifConfig(let clauses):
                var taken = names.taken
                for clause in clauses {
                    var branch = names
                    walk(clause.items, names: &branch, body)
                    taken.formUnion(branch.taken)
                }
                names.taken = taken
            }
        }
    }

    private static func declaredNames(
        in members: MemberBlockItemListSyntax
    ) -> Set<String> {
        var names = Set<String>()
        for member in members {
            let decl = member.decl
            if let variable = decl.as(VariableDeclSyntax.self) {
                for binding in variable.bindings {
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                        names.insert(pattern.identifier.text.unescaped)
                    }
                }
            } else if let named = decl.asProtocol(NamedDeclSyntax.self) {
                names.insert(named.name.text.unescaped)
            } else if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
                for clause in ifConfig.clauses {
                    if case .decls(let decls) = clause.elements {
                        names.formUnion(declaredNames(in: decls))
                    }
                }
            }
        }
        return names
    }

    private static let knownVisibilityKeywords: Set<String> = ["public", "package", "internal", "fileprivate", "private"]

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
        // A `private` member of a `private` type is only visible within the type
        if visibility == "private" {
            return "fileprivate "
        }
        return "\(visibility) "
    }

    // MARK: - Fields

    private struct Field {
        var index: Int
        var type: TypeSyntax
        /// The external label used to construct the case
        var callLabel: String?
        /// The label of the element in the tuple accessor
        var tupleLabel: String?
        var accessorName: String

        var isOptional: Bool {
            UnionMacro.isOptional(type)
        }

        var tupleElement: String {
            if let tupleLabel {
                return "\(tupleLabel): \(type.trimmedDescription)"
            }
            return type.trimmedDescription
        }

        func argument(_ value: String) -> String {
            if let callLabel {
                return "\(callLabel): \(value)"
            }
            return value
        }
    }

    private struct Plan {
        var fields: [Field]
        var isAccessor: String?
        /// The accessor for a single associated value, or the tuple of all associated values
        var valueAccessor: String?
        var fieldAccessors: Set<Int> = []

        func valueAccessorName(for element: EnumCaseElementSyntax) -> String? {
            switch fields.count {
            case 0:
                return nil
            case 1:
                return fields[0].accessorName
            default:
                return element.name.text
            }
        }
    }

    private static func makeFields(
        for element: EnumCaseElementSyntax
    ) -> [Field] {
        guard let parameters = element.parameterClause?.parameters else {
            return []
        }
        let name = element.name.text
        let base = name.unescaped
        var fields = parameters.enumerated().map { index, parameter -> Field in
            let firstName = parameter.firstName?.text
            let secondName = parameter.secondName?.text
            let callLabel = firstName == "_" ? nil : firstName
            let tupleLabel = callLabel ?? (secondName == "_" ? nil : secondName)
            let accessorName: String
            if parameters.count == 1 {
                accessorName = callLabel.map { base + $0.unescaped.uppercasedFirst } ?? name
            } else if let suffix = tupleLabel ?? simpleTypeName(parameter.type) {
                accessorName = base + suffix.unescaped.uppercasedFirst
            } else {
                accessorName = ""
            }
            return Field(
                index: index,
                type: parameter.type,
                callLabel: callLabel,
                tupleLabel: tupleLabel,
                accessorName: accessorName
            )
        }
        // Fall back to positional names for unlabeled values when the type name
        // is not a valid identifier or is ambiguous, such as `case pair(Int, Int)`
        let accessorNames = fields.map { $0.accessorName }
        if fields.count > 1,
            accessorNames.contains("") || Set(accessorNames).count != accessorNames.count
        {
            for index in fields.indices where fields[index].tupleLabel == nil {
                fields[index].accessorName = "\(base)\(index)"
            }
        }
        return fields
    }

    private static func simpleTypeName(_ type: TypeSyntax) -> String? {
        if let optional = type.as(OptionalTypeSyntax.self) {
            return simpleTypeName(optional.wrappedType)
        }
        if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return simpleTypeName(optional.wrappedType)
        }
        if let identifier = type.as(IdentifierTypeSyntax.self), identifier.genericArgumentClause == nil {
            return identifier.name.text
        }
        if let member = type.as(MemberTypeSyntax.self), member.genericArgumentClause == nil {
            return member.name.text
        }
        return nil
    }

    // MARK: - Types

    private static func isOptional(_ type: TypeSyntax) -> Bool {
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

    /// The type of an accessor that returns `nil` when the enum is a different case.
    private static func optionalType(_ type: TypeSyntax) -> String {
        if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return "\(parenthesized(optional.wrappedType))?"
        }
        if isOptional(type) {
            return type.trimmedDescription
        }
        return "\(parenthesized(type))?"
    }

    /// Wraps types such as `() -> Void` or `any P` so a postfix `?` applies to the whole type.
    private static func parenthesized(_ type: TypeSyntax) -> String {
        if type.is(IdentifierTypeSyntax.self)
            || type.is(MemberTypeSyntax.self)
            || type.is(ArrayTypeSyntax.self)
            || type.is(DictionaryTypeSyntax.self)
            || type.is(TupleTypeSyntax.self)
            || type.is(OptionalTypeSyntax.self)
            || type.is(MetatypeTypeSyntax.self)
        {
            return type.trimmedDescription
        }
        return "(\(type.trimmedDescription))"
    }

    // MARK: - Code Generation

    private static func makeCaseKeyEnum(
        items: [CaseItem],
        prefix: String
    ) -> String {
        let caseList = emit(items, separator: "\n") { unionCase in
            ["case \(unionCase.element.name.text)"]
        }.joined(separator: "\n")

        return """
        \(prefix)enum CaseKey: Hashable, Sendable, CaseIterable {
            \(caseList)
        }
        """
    }

    private static func makeCaseKeyAccessor(
        items: [CaseItem],
        prefix: String
    ) -> String {
        let arms = emit(items, separator: "\n") { unionCase in
            let name = unionCase.element.name.text
            return [
                """
                    case .\(name):
                        return .\(name)
                """
            ]
        }.joined(separator: "\n")

        return """
        \(prefix)var key: CaseKey {
            switch self {
        \(arms)
            }
        }
        """
    }

    private static func makeAccessors(
        for unionCase: Case,
        plan: Plan,
        prefix: String
    ) -> [String] {
        let element = unionCase.element
        let name = element.name.text
        let fields = plan.fields
        let attributes = unionCase.attributes
        var accessors: [String] = []

        if let isAccessor = plan.isAccessor {
            accessors.append(
                makeAccessor(
                    name: isAccessor,
                    prefix: prefix,
                    attributes: attributes,
                    returnType: "Bool",
                    getter: """
                    switch self {
                    case .\(name): return true
                    default: return false
                    }
                    """,
                    setter: fields.isEmpty ? """
                    guard newValue else { return }
                    self = .\(name)
                    """ : nil
                )
            )
        }

        if fields.count == 1, let valueAccessor = plan.valueAccessor {
            let field = fields[0]
            let setter: String
            if field.isOptional {
                setter = """
                self = .\(name)(\(field.argument("newValue")))
                """
            } else {
                setter = """
                guard let newValue else { return }
                self = .\(name)(\(field.argument("newValue")))
                """
            }
            accessors.append(
                makeAccessor(
                    name: valueAccessor,
                    prefix: prefix,
                    attributes: attributes,
                    returnType: optionalType(field.type),
                    getter: """
                    switch self {
                    case .\(name)(let v0): return v0
                    default: return nil
                    }
                    """,
                    setter: setter
                )
            )
        }

        guard fields.count > 1 else {
            return accessors
        }

        for field in fields where plan.fieldAccessors.contains(field.index) {
            let getPattern = fields.map {
                $0.index == field.index ? "let v\($0.index)" : "_"
            }.joined(separator: ", ")

            let mutatePattern = fields.map {
                $0.index == field.index ? "_" : "let v\($0.index)"
            }.joined(separator: ", ")

            let setPattern = fields.map {
                $0.argument($0.index == field.index ? "newValue" : "v\($0.index)")
            }.joined(separator: ", ")

            // Optional values can be cleared, so `nil` is only ignored for non-optional values
            let condition = field.isOptional
                ? "case .\(name)(\(mutatePattern)) = self"
                : "let newValue, case .\(name)(\(mutatePattern)) = self"

            accessors.append(
                makeAccessor(
                    name: field.accessorName,
                    prefix: prefix,
                    attributes: attributes,
                    returnType: optionalType(field.type),
                    getter: """
                    switch self {
                    case .\(name)(\(getPattern)): return v\(field.index)
                    default: return nil
                    }
                    """,
                    setter: """
                    guard \(condition) else { return }
                    self = .\(name)(\(setPattern))
                    """
                )
            )
        }

        if let valueAccessor = plan.valueAccessor {
            let allOptional = fields.allSatisfy { $0.isOptional }

            let getPattern = fields.map {
                "let v\($0.index)"
            }.joined(separator: ", ")

            let returnPattern = fields.map { field in
                if let label = field.tupleLabel {
                    return "\(label): v\(field.index)"
                }
                return "v\(field.index)"
            }.joined(separator: ", ")

            let setPattern = fields.map { field in
                let member = field.tupleLabel ?? "\(field.index)"
                return field.argument("newValue\(allOptional ? "?" : "").\(member)")
            }.joined(separator: ", ")

            let setter: String
            if allOptional {
                setter = """
                self = .\(name)(\(setPattern))
                """
            } else {
                setter = """
                guard let newValue else { return }
                self = .\(name)(\(setPattern))
                """
            }

            accessors.append(
                makeAccessor(
                    name: valueAccessor,
                    prefix: prefix,
                    attributes: attributes,
                    returnType: "(\(fields.map { $0.tupleElement }.joined(separator: ", ")))?",
                    getter: """
                    switch self {
                    case .\(name)(\(getPattern)): return (\(returnPattern))
                    default: return nil
                    }
                    """,
                    setter: setter
                )
            )
        }
        return accessors
    }

    private static func makeAccessor(
        name: String,
        prefix: String,
        attributes: [String],
        returnType: String,
        getter: String,
        setter: String? = nil
    ) -> String {
        let attributes = attributes.map { "\($0)\n" }.joined()
        if let setter {
            return """
            \(attributes)\(prefix)var \(name): \(returnType) {
                get {
                    \(getter)
                }
                set {
                    \(setter)
                }
            }
            """
        }
        return """
        \(attributes)\(prefix)var \(name): \(returnType) {
            get {
                \(getter)
            }
        }
        """
    }

    // MARK: - Diagnostics

    /// The diagnostics emitted by the `@Union` macro.
    public enum Error: String, Swift.Error, CustomStringConvertible, DiagnosticMessage {
        case unsupportedType

        public var message: String {
            return description
        }

        public var diagnosticID: MessageID {
            return MessageID(domain: "UnionMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity {
            return .error
        }

        public var description: String {
            switch self {
            case .unsupportedType:
                return "UnionMacro can only be applied to an enum"
            }
        }
    }

    private struct NameCollision: DiagnosticMessage {
        var name: String

        var message: String {
            "UnionMacro skipped generating '\(name)' because the name is already in use"
        }

        var diagnosticID: MessageID {
            MessageID(domain: "UnionMacro", id: "nameCollision")
        }

        var severity: DiagnosticSeverity {
            .warning
        }
    }
}

extension String {

    fileprivate var unescaped: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "`"))
    }

    fileprivate var uppercasedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
