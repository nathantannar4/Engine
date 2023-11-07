//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EmptyView: MultiView {

    public func makeSubviewIterator() -> some MultiViewIterator {
        EmptySubviewIterator()
    }
}

private struct EmptySubviewIterator: MultiViewIterator {

    mutating func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        // Do nothing
    }
}
