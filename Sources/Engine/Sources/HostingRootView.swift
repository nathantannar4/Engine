//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// The root view of a ``HostingView``, which applies a transaction to its content when updated.
@frozen
public struct HostingRootView<Content: View>: View {

    /// The hosted content.
    public var content: Content
    /// The transaction applied to the content when it is updated.
    public var transaction: Transaction

    /// Creates a root view for the content that applies the transaction when updated.
    @inlinable
    public init(
        content: Content,
        transaction: Transaction
    ) {
        self.content = content
        self.transaction = transaction
    }

    public var body: some View {
        _Body(
            content: content,
            transaction: transaction
        )
    }

    struct _Body: VersionedView {
        var content: Content
        var transaction: Transaction

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        struct V2Body: View {
            var content: Content
            var transaction: Transaction

            @UpdatePhase private var phase

            var body: some View {
                content
                    .transaction(transaction, value: phase)
            }
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public var v2Body: V2Body {
            V2Body(
                content: content,
                transaction: transaction
            )
        }

        struct V1Body: View {
            var content: Content
            var transaction: Transaction

            var body: some View {
                content
                    .transaction { $0 = transaction }
            }
        }

        var v1Body: V1Body {
            V1Body(
                content: content,
                transaction: transaction
            )
        }
    }
}
