//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is dynamically either `TrueContent` or `FalseContent`.
///
/// > Note: Similar to `SwiftUI._ConditionalContent` but with the underlying storage
/// made public
@frozen
public struct ConditionalContent<
    TrueContent,
    FalseContent
> {

    @frozen
    public enum Storage {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }

    public var storage: Storage

    @inlinable
    public init(_ trueContent: TrueContent) {
        self.storage = .trueContent(trueContent)
    }

    @inlinable
    public init(_ falseContent: FalseContent) {
        self.storage = .falseContent(falseContent)
    }
}

extension ConditionalContent: View where TrueContent: View, FalseContent: View {
    @inlinable
    public init(
        if condition: Bool,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder else: () -> FalseContent
    ) {
        self.storage = condition ? .trueContent(then()) : .falseContent(`else`())
    }

    public var body: some View {
        switch storage {
        case .trueContent(let trueContent):
            trueContent
        case .falseContent(let falseContent):
            falseContent
        }
    }
}

extension ConditionalContent where TrueContent: View, FalseContent == EmptyView {
    @inlinable
    public init(
        if condition: Bool,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(if: condition, then: then, else: { EmptyView() })
    }
}

extension ConditionalContent: Equatable where TrueContent: Equatable, FalseContent: Equatable {
    public static func == (lhs: ConditionalContent<TrueContent, FalseContent>, rhs: ConditionalContent<TrueContent, FalseContent>) -> Bool {
        switch (lhs.storage, rhs.storage) {
        case (.trueContent(let lhs), .trueContent(let rhs)):
            return lhs == rhs
        case (.falseContent(let lhs), .falseContent(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

// MARK: - Previews

struct ConditionalContent_Previews: PreviewProvider {
    struct Preview: View {
        @State var condition = true

        var body: some View {
            VStack {
                Toggle(
                    isOn: $condition.animation(.default),
                    label: { EmptyView() }
                )
                .labelsHidden()

                ConditionalContent(if: condition) {
                    VStack {
                        content
                    }
                } else: {
                    HStack {
                        content
                    }
                }
            }
        }

        @ViewBuilder
        var content: some View {
            Text("Hello")
            Text("World")
        }
    }

    static var previews: some View {
        Preview()
    }
}
