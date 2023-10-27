//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Optional: MultiView where Wrapped: View {

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return 1
    }

    public subscript(position: Int) -> Self {
        precondition(position == 0, "Index out of range")
        return self
    }

    public func makeIterator() -> OptionalMultiViewIterator<Wrapped> {
        OptionalMultiViewIterator(content: self)
    }
}

@frozen
public struct OptionalMultiViewIterator<
    Wrapped: View
>: MultiViewIterator {

    public var content: Optional<Wrapped>
    public init(content: Optional<Wrapped>) {
        self.content = content
    }

    public mutating func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        switch content {
        case .none:
            visitor.value.visit(element: content, context: _MultiViewVisitorContext(flags: .null))
        case .some(let element):
            visitor.value.visit(element: element, context: .init())
        }
    }
}
