import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(EngineMacrosCore)
@testable import EngineMacrosCore

let testMacros: [String: Macro.Type] = [
    "StyledView": StyledViewMacro.self,
]

final class MacroTests: XCTestCase {
    func testMacro() throws {
        let sourceInput = """
        @StyledView
        struct LabelView<Label: View, Content: View>: StyledView {
            var label: Label
            var content: Content
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?

            var body: some View {
                HStack {
                    label
                    content
                }
                .id(identifier)
            }
        }
        """
        let sourceOutput = """
        struct LabelView<Label: View, Content: View>: StyledView {
            var label: Label
            var content: Content
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?

            var body: some View {
                HStack {
                    label
                    content
                }
                .id(identifier)
            }

            var _body: some View {
                LabelViewBody(
                    configuration: LabelViewConfiguration(
                        identifier: identifier,
                        value: value,
                        traits: traits,
                        action: action,
                        completion: completion,
                        isEnabled: $isEnabled,
                        selection: selection
                    )
                )
                .viewAlias(LabelViewConfiguration.Label.self) {
                    label
                }
                .viewAlias(LabelViewConfiguration.Content.self) {
                    content
                }
            }

            init(
                identifier: String,
                value: String? = nil,
                traits: Array<Int>,
                isEnabled: Binding<Bool>,
                selection: Binding<Int>? = nil,
                action: @escaping () -> Void,
                completion: ((Bool) -> Void)? = nil,
                @ViewBuilder label: () -> Label,
                @ViewBuilder content: () -> Content
            ) {
                self.label = label()
                self.content = content()
                self.identifier = identifier
                self.value = value
                self.traits = traits
                self.action = action
                self.completion = completion
                self._isEnabled = isEnabled
                self.selection = selection
            }

            init(
                _ configuration: LabelViewConfiguration
            ) where Label == LabelViewConfiguration.Label, Content == LabelViewConfiguration.Content {
                self.label = configuration.label
                self.content = configuration.content
                self.identifier = configuration.identifier
                self.value = configuration.value
                self.traits = configuration.traits
                self.action = configuration.action
                self.completion = configuration.completion
                self._isEnabled = configuration.$isEnabled
                self.selection = configuration.selection
            }
        }

        struct LabelViewConfiguration {
            struct Label: ViewAlias {
            }
            var label: Label {
                .init()
            }
            struct Content: ViewAlias {
            }
            var content: Content {
                .init()
            }
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?
        }

        protocol LabelViewStyle: ViewStyle where Configuration == LabelViewConfiguration {
        }

        struct LabelViewDefaultStyle: LabelViewStyle {
            func makeBody(configuration: LabelViewConfiguration) -> some View {
                _DefaultStyledView(LabelView(configuration))
            }
        }

        private struct LabelViewBody: ViewStyledView {
            var configuration: LabelViewConfiguration

            static var defaultStyle: LabelViewDefaultStyle {
                LabelViewDefaultStyle()
            }
        }

        struct LabelViewStyleModifier<Style: LabelViewStyle>: ViewModifier {
            var style: Style

            init(_ style: Style) {
                self.style = style
            }

            func body(content: Content) -> some View {
                content.styledViewStyle(LabelViewBody.self, style: style)
            }
        }
        """
        assertMacroExpansion(
            sourceInput,
            expandedSource: sourceOutput,
            macros: testMacros
        )
    }
}

#endif
