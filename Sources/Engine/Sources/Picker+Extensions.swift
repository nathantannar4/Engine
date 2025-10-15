//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Picker {

    public init<
        ValueLabel: View
    >(
        sources: [SelectionValue],
        selection: Binding<SelectionValue>,
        @ViewBuilder content: (SelectionValue) -> ValueLabel,
        @ViewBuilder label: () -> Label
    ) where Content == ForEach<Array<(SelectionValue, ValueLabel)>, SelectionValue, ValueLabel> {
        let labels = sources.map { content($0) }
        self.init(selection: selection) {
            ForEach(Array(zip(sources, labels)), id: \.0) { source, label in
                label
            }
        } label: {
            label()
        }
    }

    @MainActor
    public init<
        _SelectionValue: Hashable,
        ValueLabel: View,
        ClearSelectionLabel: View
    >(
        sources: [_SelectionValue],
        selection: Binding<_SelectionValue?>,
        @ViewBuilder content: (_SelectionValue) -> ValueLabel,
        @ViewBuilder label: () -> Label,
        @ViewBuilder clearSelectionLabel: () -> ClearSelectionLabel
    ) where SelectionValue == Optional<_SelectionValue>, Content == TupleView<(NilSelectionLabel<_SelectionValue, ClearSelectionLabel>, ForEach<Array<(_SelectionValue, ValueLabel)>, SelectionValue, ValueLabel>)> {
        let labels = sources.map { content($0) }
        self.init(selection: selection) {
            NilSelectionLabel<_SelectionValue, ClearSelectionLabel>(
                content: clearSelectionLabel()
            )

            ForEach(Array(zip(sources, labels)), id: \.0.optional) { source, label in
                label
            }
        } label: {
            label()
        }
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension Picker {

    public init<
        ValueLabel: View,
        CurrentValueLabel: View
    >(
        sources: [SelectionValue],
        selection: Binding<SelectionValue>,
        @ViewBuilder content: (SelectionValue) -> ValueLabel,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: (SelectionValue) -> CurrentValueLabel,
    ) where Content == ForEach<Array<(SelectionValue, ValueLabel)>, SelectionValue, ValueLabel> {
        let labels = sources.map { content($0) }
        self.init(selection: selection) {
            ForEach(Array(zip(sources, labels)), id: \.0) { source, label in
                label
            }
        } label: {
            label()
        } currentValueLabel: {
            currentValueLabel(selection.wrappedValue)
        }
    }

    @MainActor
    public init<
        _SelectionValue: Hashable,
        ValueLabel: View,
        CurrentValueLabel: View,
        ClearSelectionLabel: View
    >(
        sources: [_SelectionValue],
        selection: Binding<_SelectionValue?>,
        @ViewBuilder content: (_SelectionValue) -> ValueLabel,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: (SelectionValue) -> CurrentValueLabel,
        @ViewBuilder clearSelectionLabel: () -> ClearSelectionLabel
    ) where SelectionValue == Optional<_SelectionValue>, Content == TupleView<(NilSelectionLabel<_SelectionValue, ClearSelectionLabel>, ForEach<Array<(_SelectionValue, ValueLabel)>, SelectionValue, ValueLabel>)> {
        let labels = sources.map { content($0) }
        self.init(selection: selection) {
            NilSelectionLabel<_SelectionValue, ClearSelectionLabel>(
                content: clearSelectionLabel()
            )

            ForEach(Array(zip(sources, labels)), id: \.0.optional) { source, label in
                label
            }
        } label: {
            label()
        } currentValueLabel: {
            currentValueLabel(selection.wrappedValue)
        }
    }
}

@frozen
public struct NilSelectionLabel<
    SelectionValue: Hashable,
    Content: View>: View {

    public var content: Content

    public init(content: Content) {
        self.content = content
    }

    public var body: some View {
        content
            .tag(Optional<SelectionValue>.none)
    }
}

// MARK: - Previews

struct Picker_Previews: PreviewProvider {

    enum PreviewPickerSource: Hashable, CaseIterable {
        case one
        case two
        case three
    }

    struct Preview: View {
        @State var selection: PreviewPickerSource = .one
        @State var optionalSelection: PreviewPickerSource?

        var body: some View {
            VStack {
                let picker = Picker(sources: PreviewPickerSource.allCases, selection: $selection) { source in
                    Text(verbatim: "\(source)")
                } label: {
                    Text(verbatim: "Label")
                }

                let optionalPicker = Picker(sources: PreviewPickerSource.allCases, selection: $optionalSelection) { source in
                    Text(verbatim: "\(source)")
                } label: {
                    Text(verbatim: "Label")
                } clearSelectionLabel: {
                    Text(verbatim: "none")
                }

                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                    let pickerWithValue = Picker(sources: PreviewPickerSource.allCases, selection: $selection) { source in
                        Text(verbatim: "\(source)")
                    } label: {
                        Text(verbatim: "Label")
                    } currentValueLabel: { source in
                        Text(verbatim: "Selected: \(source)")
                    }

                    pickerWithValue
                }

                picker

                optionalPicker
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}

