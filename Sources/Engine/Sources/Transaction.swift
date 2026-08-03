//
// Copyright (c) Nathan Tannar
//

import SwiftUI

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

    public var isAnimated: Bool {
        let isAnimated = animation != nil
        return isAnimated
    }

    public func animation(_ animation: Animation?) -> Transaction {
        var copy = self
        copy.animation = animation
        return copy
    }

    public func disablesAnimations(_ disablesAnimations: Bool) -> Transaction {
        var copy = self
        copy.disablesAnimations = disablesAnimations
        return copy
    }
}

extension Optional where Wrapped == Transaction {
    public var isAnimated: Bool {
        switch self {
        case .none:
            return false
        case .some(let transation):
            return transation.isAnimated
        }
    }
}
