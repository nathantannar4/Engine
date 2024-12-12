import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(EngineMacrosCore)
@testable import EngineMacrosCore

let testMacros: [String: Macro.Type] = [
    "StyledView": StyledViewMacro.self,
]

final class MyMacroTests: XCTestCase {
    func testMacro() throws {
        let sourceInput = """
        @StyledView
        struct LabelView<Label: View, Content: View>: StyledView {
            var label: Label
            var content: Content
            var identifier: String
            var traits: Array<Int>
            @Binding var isEnabled: Bool

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
            var traits: Array<Int>
            @Binding var isEnabled: Bool

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
                        traits: traits,
                        isEnabled: $isEnabled
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
                @ViewBuilder label: () -> Label,
                @ViewBuilder content: () -> Content,
                identifier: String,
                traits: Array<Int>,
                isEnabled: Binding<Bool>
            ) {
                self.label = label()
                self.content = content()
                self.identifier = identifier
                self.traits = traits
                self._isEnabled = isEnabled
            }

            init(
                _ configuration: LabelViewConfiguration
            ) where Label == LabelViewConfiguration.Label, Content == LabelViewConfiguration.Content {
                self.label = configuration.label
                self.content = configuration.content
                self.identifier = configuration.identifier
                self.traits = configuration.traits
                self._isEnabled = configuration.isEnabled
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
            var traits: Array<Int>
            var isEnabled: Binding<Bool>
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
