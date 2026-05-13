//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EnumKeyPathsMacro: MemberMacro {

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
            throw Error.unsupportedType
        }

        let members = declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements }

        let prefix = getPrefix(
            modifiers: declaration.modifiers
        )

        var declarations: [DeclSyntax] = []

        if members.contains(where: { $0.parameterClause != nil }) {
            declarations.append(
                DeclSyntax(
                    stringLiteral: makeCaseKeyEnum(
                        cases: members,
                        prefix: prefix
                    )
                )
            )

            declarations.append(
                DeclSyntax(
                    stringLiteral: makeCaseKeyAccessor(
                        cases: members,
                        prefix: prefix
                    )
                )
            )
        }

        for member in members {
            declarations.append(
                DeclSyntax(
                    stringLiteral: makeIsCaseAccessor(
                        member: member,
                        prefix: prefix,
                        hasAssociatedValues: member.parameterClause != nil
                    )
                )
            )
            if let parameters = member.parameterClause?.parameters {
                let associatedValueAccessors = makeAssociatedValueAccessors(
                    member: member,
                    prefix: prefix,
                    associatedValues: parameters
                )
                declarations.append(
                    contentsOf: associatedValueAccessors.map({
                        DeclSyntax(
                            stringLiteral: $0
                        )
                    })
                )
            }
        }
        return declarations
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

    private static func makeCaseKeyEnum(
        cases: [EnumCaseElementSyntax],
        prefix: String
    ) -> String {
        let caseList = cases
            .map { "case \($0.name.text)" }
            .joined(separator: "\n")

        return """
        \(prefix)enum CaseKey {
            \(caseList)
        }
        """
    }

    private static func makeCaseKeyAccessor(
        cases: [EnumCaseElementSyntax],
        prefix: String
    ) -> String {
        let arms = cases.map { element in
            let name = element.name.text
            return """
                case .\(name):
                    return .\(name)
            """
        }.joined(separator: "\n")

        return """
        \(prefix)var key: CaseKey {
            switch self {
        \(arms)
            }
        }
        """
    }

    private static func makeIsCaseAccessor(
        member: EnumCaseElementListSyntax.Element,
        prefix: String,
        hasAssociatedValues: Bool
    ) -> String {
        return makeAccessor(
            name: "is\(member.caseName)",
            prefix: prefix,
            returnType: "Bool",
            getter: """
            switch self {
            case .\(member.name.text): return true
            default: return false
            }
            """,
            setter: hasAssociatedValues ? nil : """
            guard newValue else { return }
            self = .\(member.name.text)
            """
        )
    }

    private static func makeAccessor(
        name: String,
        prefix: String,
        returnType: String,
        getter: String,
        setter: String? = nil
    ) -> String {
        if let setter {
            return """
            \(prefix)var \(name): \(returnType) {
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
        \(prefix)var \(name): \(returnType) {
            get {
                \(getter)
            }
        }
        """
    }

    private static func makeAssociatedValueAccessors(
        member: EnumCaseElementListSyntax.Element,
        prefix: String,
        associatedValues: EnumCaseParameterListSyntax
    ) -> [String] {
        let name = member.name.text
        var accessors = associatedValues.enumerated().compactMap { i, associatedValue -> String? in
            var label = name
            let returnType = associatedValue.type.description
            let isOptional = returnType.hasSuffix("?")

            if let name = associatedValue.firstName?.text {
                label.append(name.capitalized)
            } else if associatedValues.count > 1 {
                if isOptional {
                    label.append(associatedValue.type.description.replacingOccurrences(of: "?", with: ""))
                } else {
                    label.append(associatedValue.type.description)
                }
            }

            let getPattern = (0..<associatedValues.count).map { j in
                return j == i ? "let v\(j)" : "_"
            }.joined(separator: ", ")

            let setPattern = associatedValues.enumerated().map { j, value in
                let label = value.firstName.map { "\($0.text): " } ?? ""
                return "\(label)\(j == i ? "newValue" : "v\(j)")"
            }.joined(separator: ", ")



            let getter = """
            switch self {
            case .\(name)(\(getPattern)): return v\(i)
            default: return nil
            }
            """
            let setter: String
            if associatedValues.count == 1 {
                if isOptional {
                    setter = """
                    self = .\(name)(\(setPattern))
                    """
                } else {
                    setter = """
                    guard let newValue else { return }
                    self = .\(name)(\(setPattern))
                    """
                }
            } else {
                let mutatePattern = (0..<associatedValues.count).map { j in
                    return j == i ? "_" : "let v\(j)"
                }.joined(separator: ", ")

                setter = """
                guard let newValue, case .\(name)(\(mutatePattern)) = self else { return }
                self = .\(name)(\(setPattern))
                """
            }

            return makeAccessor(
                name: label,
                prefix: prefix,
                returnType: isOptional ? returnType : "\(returnType)?",
                getter: getter,
                setter: setter
            )
        }
        if associatedValues.count > 1 {
            let types = associatedValues
                .map {
                    if let label = $0.firstName?.text {
                        return "\(label): \($0.type.description)"
                    }
                    return $0.type.description
                }
            let allOptional = types.allSatisfy({ $0.hasSuffix("?") })

            let returnPatterm = associatedValues.enumerated().map { j, value in
                if let label = value.firstName?.text {
                    return "\(label): v\(j)"
                }
                return "v\(j)"
            }.joined(separator: ", ")

            let getPattern = (0..<associatedValues.count).map { j in
                return "let v\(j)"
            }.joined(separator: ", ")

            let setPattern = associatedValues.enumerated().map { j, value in
                let suffix = allOptional ? "?" : ""
                if let label = value.firstName?.text {
                    return "\(label): newValue\(suffix).\(label)"
                }
                return "newValue\(suffix).\(j)"
            }.joined(separator: ", ")

            let getter = """
            switch self {
            case .\(name)(\(getPattern)): return (\(returnPatterm))
            default: return nil
            }
            """
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

            let tupleAccessor = makeAccessor(
                name: name,
                prefix: prefix,
                returnType: "(\(types.joined(separator: ", ")))?",
                getter: getter,
                setter: setter
            )
            accessors.append(tupleAccessor)
        }
        return accessors
    }

    public enum Error: String, Swift.Error, CustomStringConvertible, DiagnosticMessage {
        case unsupportedType

        public var message: String {
            return description
        }

        public var diagnosticID: MessageID {
            return MessageID(domain: "EnumKeyPathsMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity {
            return .error
        }

        public var description: String {
            switch self {
            case .unsupportedType:
                return "EnumKeyPathsMacro can only be applied to an enum"
            }
        }
    }
}


extension EnumCaseElementListSyntax.Element {

    var caseName: String {
        let trimmed = name.text.replacingOccurrences(of: "`", with: "")
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}
