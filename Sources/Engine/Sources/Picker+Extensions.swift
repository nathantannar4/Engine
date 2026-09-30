//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Picker {

    /// Creates a picker that generates its options from an array of values.
    ///
    /// - Parameters:
    ///   - sources: The values to choose from, in display order.
    ///   - selection: A binding to the selected value.
    ///   - content: A view builder that creates the label for each value.
    ///   - label: A view that describes the purpose of selecting an option.
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

    /// Creates a picker with an optional selection that generates its options
    /// from an array of values, along with an option that clears the selection.
    ///
    /// - Parameters:
    ///   - sources: The values to choose from, in display order.
    ///   - selection: A binding to the optional selected value.
    ///   - content: A view builder that creates the label for each value.
    ///   - label: A view that describes the purpose of selecting an option.
    ///   - clearSelectionLabel: The label for the option that sets the selection to `nil`.
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

    /// Creates a picker that generates its options from an array of values,
    /// with a custom label for the current value.
    ///
    /// - Parameters:
    ///   - sources: The values to choose from, in display order.
    ///   - selection: A binding to the selected value.
    ///   - content: A view builder that creates the label for each value.
    ///   - label: A view that describes the purpose of selecting an option.
    ///   - currentValueLabel: A view builder that creates the label for the selected value.
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

    /// Creates a picker with an optional selection that generates its options
    /// from an array of values, with a custom label for the current value.
    ///
    /// - Parameters:
    ///   - sources: The values to choose from, in display order.
    ///   - selection: A binding to the optional selected value.
    ///   - content: A view builder that creates the label for each value.
    ///   - label: A view that describes the purpose of selecting an option.
    ///   - currentValueLabel: A view builder that creates the label for the selected value.
    public init<
        _SelectionValue: Hashable,
        ValueLabel: View,
        CurrentValueLabel: View
    >(
        sources: [_SelectionValue],
        selection: Binding<SelectionValue>,
        @ViewBuilder content: (_SelectionValue) -> ValueLabel,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: (SelectionValue) -> CurrentValueLabel,
    ) where SelectionValue == Optional<_SelectionValue>, Content == ForEach<Array<(_SelectionValue, ValueLabel)>, _SelectionValue, ValueLabel> {
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

    /// Creates a picker with an optional selection that generates its options
    /// from an array of values, with a custom label for the current value and
    /// an option that clears the selection.
    ///
    /// - Parameters:
    ///   - sources: The values to choose from, in display order.
    ///   - selection: A binding to the optional selected value.
    ///   - content: A view builder that creates the label for each value.
    ///   - label: A view that describes the purpose of selecting an option.
    ///   - currentValueLabel: A view builder that creates the label for the selected value.
    ///   - clearSelectionLabel: The label for the option that sets the selection to `nil`.
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

/// A picker option that is tagged with a `nil` selection value.
@frozen
public struct NilSelectionLabel<
    SelectionValue: Hashable,
    Content: View>: View {

    /// The label of the option.
    public var content: Content

    /// Creates a `nil` selection option with the given label.
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

