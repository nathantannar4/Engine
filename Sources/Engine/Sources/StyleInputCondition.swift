//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Evaluates ``ViewInputs`` for the existence of `Style`
@frozen
public struct StyleInputCondition<Style>: ViewInputsCondition {

    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        var visitor = Visitor(type: _typeName(Style.self, qualified: true))
        inputs.visit(visitor: &visitor)
        return visitor.hasStyle
    }

    struct Visitor: ViewInputsVisitor {
        var type: String
        var hasStyle = false
        var seenStyleKinds: Set<Substring> = []

        mutating func visit<Value>(
            _ value: Value,
            key: String,
            stop: inout Bool
        ) {
            if key.contains("StyleInput") {
                let mirror = Mirror(reflecting: value)
                // SwiftUI's style type boxes name the field `base` (AnyButtonStyleType) or `type`, and the value
                // arrives wrapped in an Optional
                let valueType = mirror.descendant("some", "base")
                    ?? mirror.descendant("some", "type")
                    ?? mirror.descendant("some", "node", "value", "_type")
                    ?? mirror.descendant("node", "value", "_type")
                guard let valueType = valueType as? Any.Type else { return }
                // Inputs are visited innermost first, and the innermost style of a kind wins. SwiftUI stores one
                // button style under StyleInput<PrimitiveButtonStyleConfiguration>, ButtonStyleInput and
                // EffectiveButtonStyleInput, so the kind comes from the key's style name.
                guard seenStyleKinds.insert(Self.styleKind(of: key)).inserted else { return }
                hasStyle = _typeName(valueType, qualified: true).contains(type)
            } else if key.contains("Engine.ViewStyleModifier") {
                hasStyle = key.contains(type)
            }
            stop = hasStyle
        }

        static func styleKind(of key: String) -> Substring {
            guard let range = key.range(of: "[A-Za-z]+Style(?=Configuration|Input)", options: .regularExpression) else {
                return Substring(key)
            }
            var kind = key[range]
            for prefix in ["Primitive", "Effective"] where kind.hasPrefix(prefix) {
                kind = kind.dropFirst(prefix.count)
            }
            return kind
        }
    }
}

// MARK: - Previews

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
                    ViewInputConditionalContent(StyleInputCondition<BorderedPreviewCustomViewStyle>.self) {
                        Color.green
                    } otherwise: {
                        Color.red
                    }
                }

                styledView

                styledView
                    .styledViewStyle(
                        PreviewCustomViewBody.self,
                        style: BorderedPreviewCustomViewStyle()
                    )
            }
        }
    }
}
#endif
