//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that reads a ``PublishedState/Binding`` so that only this view,
/// rather than its parent, is invalidated when the value changes.
///
///     @PublishedState var value = 0
///
///     var body: some View {
///         PublishedStateReader($value) { $value in
///             Text(value.description)
///         }
///     }
///
@frozen
public struct PublishedStateReader<Value, Content: View>: View {

    @PublishedState.Binding var value: Value
    var content: (Binding<Value>) -> Content

    /// Creates a reader that provides a binding to the published value to `content`.
    public init(
        _ value: PublishedState<Value>.Binding,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = value
        self.content = content
    }

    public var body: some View {
        content($value)
    }
}

// MARK: - Previews

struct PublishedStateReader_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @PublishedState var value = 0

        var body: some View {
            VStack {
                Text(value.description)

                PublishedStateReader($value) { $value in
                    Text(value.description)
                }

                Button {
                    value += 1
                } label: {
                    Text("Increment")
                }
            }
        }
    }
}
