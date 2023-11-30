//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Optional: MultiView where Wrapped: View {

    public func makeSubviewIterator() -> some MultiViewIterator {
        OptionalSubviewIterator(content: self)
    }
}

private struct OptionalSubviewIterator<
    Wrapped: View
>: MultiViewIterator {

    var content: Optional<Wrapped>

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        switch content {
        case .none:
            // Do nothing
            break
        case .some(let element):
            element.visit(visitor: visitor, context: context, stop: &stop)
        }
    }
}
