//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct UpdateTransactionModifier<Value: Equatable>: VersionedViewModifier {

    public var transaction: Transaction
    public var value: Value

    @inlinable
    public init(transaction: Transaction, value: Value) {
        self.value = value
        self.transaction = transaction
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .transaction(value: value) { value in
                value = transaction
            }
    }

    public func v1Body(content: Content) -> some View {
        content
            .animation(transaction.animation, value: value)
    }
}

extension View {

    @inlinable
    public func transaction<Value: Equatable>(
        _ transaction: Transaction,
        value: Value
    ) -> some View {
        modifier(
            UpdateTransactionModifier(
                transaction: transaction,
                value: value
            )
        )
    }
}
