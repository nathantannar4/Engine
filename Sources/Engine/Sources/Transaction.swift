//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@inline(__always)
public func withCATransaction(
    _ completion: @escaping () -> Void
) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    CATransaction.commit()
}

extension Transaction {
    public var isAnimated: Bool {
        let isAnimated = animation != nil
        return isAnimated
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
