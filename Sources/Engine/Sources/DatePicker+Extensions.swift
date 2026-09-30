//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, watchOS 10.0, *)
@available(tvOS, unavailable)
extension DatePicker {

    /// Creates a date picker based on a date picker style configuration.
    ///
    /// You can use this initializer within the `makeBody(configuration:)` method of a
    /// `DatePickerStyle` to create an instance of the styled date picker. The selection,
    /// date range and displayed components of the configuration are preserved.
    public init(
        _ configuration: DatePickerStyleConfiguration
    ) where Label == DatePickerStyleConfiguration.Label {
        self.init(configuration) { label in
            label
        }
    }

    /// Creates a date picker with a custom label based on a date picker style configuration.
    ///
    /// The selection, date range and displayed components of the configuration are preserved.
    public init(
        _ configuration: DatePickerStyleConfiguration,
        @ViewBuilder label: (DatePickerStyleConfiguration.Label) -> Label
    ) {
        if let minimumDate = configuration.minimumDate, let maximumDate = configuration.maximumDate {
            self.init(
                selection: configuration.$selection,
                in: minimumDate...maximumDate,
                displayedComponents: configuration.displayedComponents
            ) {
                label(configuration.label)
            }
        } else if let minimumDate = configuration.minimumDate {
            self.init(
                selection: configuration.$selection,
                in: minimumDate...,
                displayedComponents: configuration.displayedComponents
            ) {
                label(configuration.label)
            }
        } else if let maximumDate = configuration.maximumDate {
            self.init(
                selection: configuration.$selection,
                in: ...maximumDate,
                displayedComponents: configuration.displayedComponents
            ) {
                label(configuration.label)
            }
        } else {
            self.init(
                selection: configuration.$selection,
                displayedComponents: configuration.displayedComponents
            ) {
                label(configuration.label)
            }
        }
    }
}
