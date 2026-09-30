//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Performs `completion` once the current Core Animation transaction has committed.
///
/// On watchOS, `completion` is instead scheduled on the main run loop.
@inline(__always)
public func withCATransaction(
    _ completion: @escaping () -> Void
) {
    #if os(watchOS)
    RunLoop.main.schedule {
        completion()
    }
    #else
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    CATransaction.commit()
    #endif
}

extension Transaction {

    /// Returns `true` if the transaction has an animation.
    public var isAnimated: Bool {
        let isAnimated = animation != nil
        return isAnimated
    }

    /// Returns a copy of the transaction with `animation` set.
    public func animation(_ animation: Animation?) -> Transaction {
        var copy = self
        copy.animation = animation
        return copy
    }

    /// Returns a copy of the transaction with `disablesAnimations` set.
    public func disablesAnimations(_ disablesAnimations: Bool = true) -> Transaction {
        var copy = self
        copy.disablesAnimations = disablesAnimations
        return copy
    }
}

extension Optional where Wrapped == Transaction {
    /// Returns `true` if the transaction is not `nil` and has an animation.
    public var isAnimated: Bool {
        switch self {
        case .none:
            return false
        case .some(let transation):
            return transation.isAnimated
        }
    }
}
