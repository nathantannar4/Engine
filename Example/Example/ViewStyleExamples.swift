//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

struct ViewStyleExamples: View {
    @State var value = 0

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text("StepperView")
                    .font(.title3)
                Text("Stepper made stylable")
                    .font(.caption)
            }
            .frame(width: 160)

            VStack(alignment: .leading) {
                Text("Default Style")
                    .font(.headline)

                StepperView {
                    Text(value.description)
                } onIncrement: {
                    value += 1
                } onDecrement: {
                    value -= 1
                }

                Text("Custom Style")
                    .font(.headline)

                StepperView {
                    Text(value.description)
                } onIncrement: {
                    value += 1
                } onDecrement: {
                    value -= 1
                }
                .stepperViewStyle(InlineStepperViewStyle())
            }
        }
        
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text("LabeledView")
                    .font(.title3)
                Text("A backwards compatible port of LabeledContent")
                    .font(.caption)
            }
            .frame(width: 160)

            VStack(alignment: .leading) {
                Text("Default Style")
                    .font(.headline)

                LabeledView {
                    Text("Content")
                } label: {
                    Text("Label")
                }

                Text("Padded Style")
                    .font(.headline)

                LabeledView {
                    Text("Content")
                } label: {
                    Text("Label")
                }
                .labeledViewStyle(PaddedLabeledViewStyle())

                Text("Padded -> Bordered Style")
                    .font(.headline)

                LabeledView {
                    Text("Content")
                } label: {
                    Text("Label")
                }
                .labeledViewStyle(BorderedLabeledViewStyle())
                .labeledViewStyle(PaddedLabeledViewStyle())

                Text("Bordered -> Padded Style")
                    .font(.headline)

                LabeledView {
                    Text("Content")
                } label: {
                    Text("Label")
                }
                .labeledViewStyle(PaddedLabeledViewStyle())
                .labeledViewStyle(BorderedLabeledViewStyle())

                LabeledView {
                    Text("Content")
                } label: {
                    Text("Label")
                }
                .labeledViewStyle(LeadingLabeledViewStyle())
                .labeledViewStyle(BorderedLabeledViewStyle())
            }
        }

        if #available(iOS 15.0, macOS 12.0, *) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("PasteboardButton")
                        .font(.title3)
                    Text("A simple example to showcase ViewStyle")
                        .font(.caption)
                }
                .frame(width: 160)

                VStack(alignment: .leading) {
                    PasteboardButton(text: "+1234567890") {
                        Text("Copy Phone")
                    }
                    .buttonStyle(BorderedButtonStyle())

                    PasteboardButton(text: "+1234567890") {
                        Text("Copy Phone")
                    }
                    .pasteboardButtonStyle(IconPasteboardButtonStyle())
                    .buttonStyle(.bordered)

                    PasteboardButton(text: "+1234567890") {
                        Text("Copy Phone")
                    }
                    .pasteboardButtonStyle(IconPasteboardButtonStyle())
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

protocol StepperViewStyle: ViewStyle where Configuration == StepperViewStyleConfiguration { }

struct StepperViewStyleConfiguration {
    struct Label: ViewAlias { }
    var label: Label { .init() }

    var onIncrement: () -> Void
    var onDecrement: () -> Void
}

struct DefaultStepperViewStyle: StepperViewStyle {
    func makeBody(configuration: StepperViewStyleConfiguration) -> some View {
        Stepper {
            configuration.label
        } onIncrement: {
            configuration.onIncrement()
        } onDecrement: {
            configuration.onDecrement()
        }
    }
}

struct InlineStepperViewStyle: StepperViewStyle {
    func makeBody(configuration: StepperViewStyleConfiguration) -> some View {
        HStack {
            Button {
                configuration.onDecrement()
            } label: {
                Image(systemName: "minus.circle.fill")
            }

            configuration.label

            Button {
                configuration.onIncrement()
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                configuration.onIncrement()
            case .decrement:
                configuration.onDecrement()
            default:
                break
            }
        }
    }
}

extension View {
    func stepperViewStyle<Style: StepperViewStyle>(_ style: Style) -> some View {
        styledViewStyle(StepperViewBody.self, style: style)
    }
}

struct StepperView<Label: View>: View {
    var label: Label
    var onIncrement: () -> Void
    var onDecrement: () -> Void

    init(
        @ViewBuilder label: () -> Label,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) {
        self.label = label()
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }

    var body: some View {
        StepperViewBody(
            configuration: .init(
                onIncrement: onIncrement,
                onDecrement: onDecrement
            )
        )
        .viewAlias(StepperViewStyleConfiguration.Label.self) {
            label
        }
    }
}

extension StepperView where Label == StepperViewStyleConfiguration.Label {
    init(_ configuration: StepperViewStyleConfiguration) {
        self.label = configuration.label
        self.onIncrement = configuration.onIncrement
        self.onDecrement = configuration.onDecrement
    }
}

struct StepperViewBody: ViewStyledView {
    var configuration: StepperViewStyleConfiguration

    var body: some View {
        StepperView(configuration)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary)
            )
    }

    static var defaultStyle: DefaultStepperViewStyle {
        DefaultStepperViewStyle()
    }
}

protocol LabeledViewStyle: ViewStyle where Configuration == LabeledViewStyleConfiguration { }

struct LabeledViewStyleConfiguration {
    struct Label: ViewAlias { }
    var label: Label { .init() }

    struct Content: ViewAlias { }
    var content: Content { .init() }
}

struct DefaultLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.label
            configuration.content
        }
    }
}

extension View {
    func labeledViewStyle<Style: LabeledViewStyle>(_ style: Style) -> some View {
        styledViewStyle(LabeledViewBody.self, style: style)
    }
}

struct LabeledView<Label: View, Content: View>: View {
    var label: Label
    var content: Content

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        LabeledViewBody(
            configuration: .init()
        )
        .viewAlias(LabeledViewStyleConfiguration.Label.self) { label }
        .viewAlias(LabeledViewStyleConfiguration.Content.self) { content }
    }
}

struct LabeledViewBody: ViewStyledView {
    var configuration: LabeledViewStyleConfiguration

    static var defaultStyle: DefaultLabeledViewStyle {
        DefaultLabeledViewStyle()
    }
}

extension LabeledView where
    Label == LabeledViewStyleConfiguration.Label,
    Content == LabeledViewStyleConfiguration.Content
{
    init(_ configuration: LabeledViewStyleConfiguration) {
        self.label = configuration.label
        self.content = configuration.content
    }
}

/// This style returns another `LabeledView`, which will be styled with the
/// next `LabeledViewStyle` that was defined, or the `DefaultLabeledViewStyle`
/// if no other style was set.
struct PaddedLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        LabeledView(configuration)
            .padding()
    }
}

/// This style returns another `LabeledView`, which will be styled with the
/// next `LabeledViewStyle` that was defined, or the `DefaultLabeledViewStyle`
/// if no other style was set.
struct BorderedLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        LabeledView(configuration)
            .border(Color.red, width: 2)
    }
}

/// This style does not return another `LabeledView`, so there will
/// be no further styling.
struct LeadingLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
    }
}

protocol PasteboardButtonStyle: ViewStyle where Configuration == PasteboardButtonStyleConfiguration { }

struct PasteboardButtonStyleConfiguration {
    struct Label: ViewAlias { }
    var label: Label { .init() }

    var text: String
}

struct DefaultPasteboardButtonStyle: PasteboardButtonStyle {
    func makeBody(configuration: PasteboardButtonStyleConfiguration) -> some View {
        configuration.label
    }
}

extension View {
    func pasteboardButtonStyle<Style: PasteboardButtonStyle>(_ style: Style) -> some View {
        styledViewStyle(PasteboardButtonBody.self, style: style)
    }
}

struct PasteboardButton<Label: View>: View {
    var label: Label
    var text: String

    init(
        text: String,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.text = text
    }

    var body: some View {
        PasteboardButtonBody(
            configuration: .init(text: text)
        )
        .viewAlias(PasteboardButtonStyleConfiguration.Label.self) { label }
    }
}

/// `body` is implemented here and not within `PasteboardButton`, since
/// multiple `PasteboardButton`'s could be used during view styling.
/// `body` is optional for a `ViewStyledView` and will be the last style
/// applied, thus this guarantees the final styled `PasteboardButton` will be
/// wrapped in a single `Button`
struct PasteboardButtonBody: ViewStyledView {
    var configuration: PasteboardButtonStyleConfiguration

    var body: some View {
        Button {
            #if os(macOS)
            NSPasteboard.general.setString(configuration.text, forType: .string)
            #else
            UIPasteboard.general.string = configuration.text
            #endif
        } label: {
            PasteboardButton(configuration)
        }
    }

    static var defaultStyle: DefaultPasteboardButtonStyle {
        DefaultPasteboardButtonStyle()
    }
}

extension PasteboardButton where
    Label == PasteboardButtonStyleConfiguration.Label
{
    init(_ configuration: PasteboardButtonStyleConfiguration) {
        self.label = configuration.label
        self.text = configuration.text
    }
}

struct IconPasteboardButtonStyle: PasteboardButtonStyle {
    func makeBody(configuration: PasteboardButtonStyleConfiguration) -> some View {
        Label {
            configuration.label
        } icon: {
            Image(systemName: "doc.on.doc.fill")
        }

    }
}

struct ViewStyleExamples_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ViewStyleExamples()
        }
    }
}
