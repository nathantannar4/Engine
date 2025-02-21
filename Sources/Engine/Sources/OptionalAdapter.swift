//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view maps an `Optional` value to it's `Content` or `Placeholder`.
@frozen
public struct OptionalAdapter<
    T,
    Content: View,
    Placeholder: View
>: View {

    @usableFromInline
    var content: ConditionalContent<Content, Placeholder>

    @inlinable
    public init(
        _ value: T?,
        @ViewBuilder content: (T) -> Content,
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
    public init(
        _ value: Binding<T?>,
        @ViewBuilder content: (Binding<T>) -> Content,
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
    public init(
        _ value: T?,
        @ViewBuilder content: (T) -> Content
    ) {
        self.init(value, content: content, placeholder: { EmptyView() })
    }

    @inlinable
    public init(
        _ value: Binding<T?>,
        @ViewBuilder content: (Binding<T>) -> Content
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
