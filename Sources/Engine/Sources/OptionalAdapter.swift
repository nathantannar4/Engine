//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Optional {

    /// Creates an optional view that is `content` when `value` is non-`nil`.
    @inlinable
    public init<Value>(
        _ value: Value?,
        @ViewBuilder content: (Value) -> Wrapped
    ) where Self == Optional<Wrapped>, Wrapped: View {
        switch value {
        case .some(let value):
            self = .some(content(value))
        case .none:
            self = .none
        }
    }

    /// Creates an optional view that is `content` when the binding's value is non-`nil`.
    @inlinable
    @MainActor @preconcurrency
    public init<Value>(
        _ value: Binding<Value?>,
        @ViewBuilder content: (Value) -> Wrapped
    ) where Self == Optional<Wrapped>, Wrapped: View {
        if let value = value.wrappedValue {
            self = .some(content(value))
        } else {
            self = .none
        }
    }

    /// Creates an optional view that is `content` when the binding's value is
    /// non-`nil`, providing an unwrapped binding to the value.
    @inlinable
    @MainActor @preconcurrency
    public init<Value>(
        _ value: Binding<Value?>,
        @ViewBuilder content: (Binding<Value>) -> Wrapped
    ) where Self == Optional<Wrapped>, Wrapped: View {
        if let value = Binding(unwrapping: value) {
            self = .some(content(value))
        } else {
            self = .none
        }
    }
}

/// A view that maps an `Optional` value to its `Content` or `Placeholder`.
@frozen
public struct OptionalAdapter<
    Content: View,
    Placeholder: View
>: View {

    @usableFromInline
    var content: ConditionalContent<Content, Placeholder>

    /// Creates a view that shows `content` when `value` is non-`nil`,
    /// otherwise `placeholder`.
    @inlinable
    public init<Value>(
        _ value: Value?,
        @ViewBuilder content: (Value) -> Content,
        @ViewBuilder placeholder: () -> Placeholder = { EmptyView() }
    ) {
        switch value {
        case .some(let value):
            self.content = .init(content(value))
        case .none:
            self.content = .init(placeholder())
        }
    }

    /// Creates a view that shows `content` with an unwrapped binding when the
    /// binding's value is non-`nil`, otherwise `placeholder`.
    @inlinable
    public init<Value>(
        _ value: Binding<Value?>,
        @ViewBuilder content: (Binding<Value>) -> Content,
        @ViewBuilder placeholder: () -> Placeholder = { EmptyView() }
    ) {
        if let value = Binding(unwrapping: value) {
            self.content = .init(content(value))
        } else {
            self.content = .init(placeholder())
        }
    }

    /// Creates a view that shows `content` when `flag` is `true`, otherwise `placeholder`.
    @inlinable
    public init(
        _ flag: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholder: () -> Placeholder = { EmptyView() }
    ) {
        self.content = flag ? .init(content()) : .init(placeholder())
    }

    public var body: some View {
        content
    }
}

extension OptionalAdapter {

    /// Creates a view that shows `content` when all of the values are
    /// non-`nil`, otherwise `placeholder`.
    @inlinable
    public init<each Value>(
        _ values: repeat (each Value)?,
        @ViewBuilder content: (repeat each Value) -> Content,
        @ViewBuilder placeholder: () -> Placeholder = { EmptyView() }
    ) {
        if let unwrapped = unwrap(repeat each values) {
            self.content = .init(content(repeat each unwrapped))
        } else {
            self.content = .init(placeholder())
        }
    }
}

// MARK: - Previews

struct OptionalAdapter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Optional(Optional.some("Hello, World")) { value in
                Text(value)
            }

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
