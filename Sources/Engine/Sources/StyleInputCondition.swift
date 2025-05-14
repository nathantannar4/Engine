//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Evaluates ``ViewInputs`` for the existence of `Style`
public struct StyleInputCondition<Style>: ViewInputsCondition {

    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        var visitor = Visitor(type: _typeName(Style.self, qualified: true))
        inputs.visit(visitor: &visitor)
        return visitor.hasStyle
    }

    struct Visitor: ViewInputsVisitor {
        var type: String
        var hasStyle = false

        mutating func visit<Value>(
            _ value: Value,
            key: String,
            stop: inout Bool
        ) {
            if key.contains("StyleInput") {
                if let valueType = Mirror(reflecting: value).descendant("some", "type") as? Any.Type {
                    hasStyle = _typeName(valueType, qualified: true).contains(type)
                } else if let valueType = Mirror(reflecting: value).descendant("node", "value", "_type") as? Any.Type {
                    hasStyle = _typeName(valueType, qualified: true).contains(type)
                }
            } else if key.contains("Engine.ViewStyleModifier") {
                hasStyle = key.contains(type)
            }
            stop = hasStyle
        }
    }
}

// MARK: - Previews

protocol PreviewCustomViewStyle: ViewStyle where Configuration == PreviewCustomViewStyleConfiguration {
    associatedtype Configuration = Configuration
}

struct PreviewCustomViewStyleConfiguration {
    struct Content: ViewAlias { }
    var content: Content { .init() }
}

struct PreviewCustomView<Content: View>: View {

    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        PreviewCustomViewBody(
            configuration: PreviewCustomViewStyleConfiguration()
        )
        .viewAlias(PreviewCustomViewStyleConfiguration.Content.self) {
            content
        }
    }
}

struct PreviewCustomViewBody: ViewStyledView {
    var configuration: PreviewCustomViewStyleConfiguration

    static var defaultStyle: DefaultPreviewCustomViewStyle { .init() }
}

struct DefaultPreviewCustomViewStyle: PreviewCustomViewStyle {
    func makeBody(configuration: PreviewCustomViewStyleConfiguration) -> some View {
        configuration.content
    }
}

struct CustomPreviewCustomViewStyle: PreviewCustomViewStyle {
    func makeBody(configuration: PreviewCustomViewStyleConfiguration) -> some View {
        configuration.content
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#if os(iOS) || os(macOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StyleInputCondition_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            HStack {
                let label = Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
                }
                .background {
                    ViewInputConditionalContent(StyleInputCondition<IconOnlyLabelStyle>.self) {
                        Color.green
                    } otherwise: {
                        Color.red
                    }
                }

                label

                label
                    .labelStyle(.iconOnly)
            }

            HStack {
                let button = Button {

                } label: {
                    Text("Action")
                }

                button
                    .background {
                        ViewInputConditionalContent(StyleInputCondition<PlainButtonStyle>.self) {
                            Color.green
                        } otherwise: {
                            Color.red
                        }
                    }

                button
                    .background {
                        ViewInputConditionalContent(StyleInputCondition<CustomButtonStyle>.self) {
                            Color.green
                        } otherwise: {
                            Color.red
                        }
                    }
                    .buttonStyle(CustomButtonStyle())

                button
                    .background {
                        ViewInputConditionalContent(StyleInputCondition<PlainButtonStyle>.self) {
                            Color.green
                        } otherwise: {
                            Color.red
                        }
                    }
                    .buttonStyle(.plain)
            }

            HStack {
                let toggle = Toggle(isOn: .constant(false)) {
                    Text("Action")
                }
                .background {
                    ViewInputConditionalContent(StyleInputCondition<ButtonToggleStyle>.self) {
                        Color.green
                    } otherwise: {
                        Color.red
                    }
                }

                toggle

                toggle
                    .toggleStyle(.button)
            }

            HStack {
                let picker = Picker(selection: .constant(0)) {
                    Text("Content")
                        .tag(0)
                } label: {
                    Text("Picker")
                }
                .background {
                    ViewInputConditionalContent(StyleInputCondition<MenuPickerStyle>.self) {
                        Color.green
                    } otherwise: {
                        Color.red
                    }
                }

                picker

                picker
                    .pickerStyle(.menu)
            }

            HStack {
                let datePicker = DatePicker("Label", selection: .constant(.now))
                    .background {
                        ViewInputConditionalContent(StyleInputCondition<CompactDatePickerStyle>.self) {
                            Color.green
                        } otherwise: {
                            Color.red
                        }
                    }

                datePicker

                datePicker
                    .datePickerStyle(.compact)
            }

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                HStack {
                    let labeledContent = LabeledContent {
                        Text("Content")
                    } label: {
                        Text("Label")
                    }
                    .background {
                        ViewInputConditionalContent(StyleInputCondition<AutomaticLabeledContentStyle>.self) {
                            Color.green
                        } otherwise: {
                            Color.red
                        }
                    }

                    labeledContent

                    labeledContent
                        .labeledContentStyle(.automatic)
                }
            }

            HStack {
                let styledView = PreviewCustomView {
                    Text("Section")
                }
                .background {
                    ViewInputConditionalContent(StyleInputCondition<CustomPreviewCustomViewStyle>.self) {
                        Color.green
                    } otherwise: {
                        Color.red
                    }
                }

                styledView

                styledView
                    .styledViewStyle(
                        PreviewCustomViewBody.self,
                        style: CustomPreviewCustomViewStyle()
                    )
            }
        }
    }
}
#endif
