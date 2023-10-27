//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension TupleView: MultiView {

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        swift_getTupleCount(value) ?? 1
    }

    public subscript(position: Int) -> Any {
        if let element = swift_getTupleElement(position, value) {
            return element
        } else if position == 0 {
            return value
        }
        preconditionFailure("Index out of range")
    }

    public func makeIterator() -> MultiViewSubviewIterator<T> {
        MultiViewSubviewIterator(content: value)
    }
}
