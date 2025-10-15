//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view maps an `Optional` value to it's `Content` or `Placeholder`.
@frozen
public struct OptionalAdapter<
    Content: View,
    Placeholder: View
>: View {

    @usableFromInline
    var content: ConditionalContent<Content, Placeholder>

    @inlinable
    public init<Value>(
        _ value: Value?,
        @ViewBuilder content: (Value) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        switch value {
        case .some(let value):
            self.content = .init(content(value))
        case .none:
            self.content = .init(placeholder())
        }
    }

    @inlinable
    public init<Value>(
        _ value: Binding<Value?>,
        @ViewBuilder content: (Binding<Value>) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        if let unwrapped = value.unwrap() {
            self.content = .init(content(unwrapped))
        } else {
            self.content = .init(placeholder())
        }
    }

    @inlinable
    public init(
        _ flag: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.content = flag ? .init(content()) : .init(placeholder())
    }

    public var body: some View {
        content
    }
}

extension OptionalAdapter where Placeholder == EmptyView {
    @inlinable
    public init<Value>(
        _ value: Value?,
        @ViewBuilder content: (Value) -> Content
    ) {
        self.init(value, content: content, placeholder: { EmptyView() })
    }

    @inlinable
    public init<Value>(
        _ value: Binding<Value?>,
        @ViewBuilder content: (Binding<Value>) -> Content
    ) {
        self.init(value, content: content, placeholder: { EmptyView() })
    }

    @inlinable
    public init(
        _ flag: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.init(flag, content: content, placeholder: { EmptyView() })
    }
}

extension OptionalAdapter {

    @inlinable
    public init<each Value>(
        _ values: repeat (each Value)?,
        @ViewBuilder content: (repeat each Value) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        if let unwrapped = unwrap(repeat each values) {
            self.content = .init(content(repeat each unwrapped))
        } else {
            self.content = .init(placeholder())
        }
    }
}

extension OptionalAdapter where Placeholder == EmptyView {

    @inlinable
    public init<each Value>(
        _ values: repeat (each Value)?,
        @ViewBuilder content: (repeat each Value) -> Content
    ) {
        self.init(repeat each values, content: content, placeholder: { EmptyView() })
    }
}

// MARK: - Previews

struct OptionalAdapter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OptionalAdapter(Optional.some("Hello, World")) { value in
                Text(value)
            }

            OptionalAdapter(Optional<String>.none) { value in
                Text(value)
            } placeholder: {
                Text("Placeholder")
            }

            OptionalAdapter(Binding.constant(Optional.some("Hello, World"))) { $value in
                Text(value)
            }

            OptionalAdapter(
                Optional.some("Line 1"),
                Optional.some("Line 2")
            ) { value1, value2 in
                Text(value1)
                Text(value2)
            }

            OptionalAdapter(
                Optional.some("Line 1"),
                Optional<String>.none
            ) { value1, value2 in
                Text(value1)
                Text(value2)
            } placeholder: {
                Text("Placeholder")
            }
        }
    }
}
