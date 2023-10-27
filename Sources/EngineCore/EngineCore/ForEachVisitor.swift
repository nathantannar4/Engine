//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension ForEach: MultiView where Content: View {

    public var startIndex: Data.Index {
        data.startIndex
    }

    public var endIndex: Data.Index {
        data.endIndex
    }

    public subscript(position: Data.Index) -> Content {
        content(data[position])
    }

    public func makeIterator() -> MultiViewForEachIterator<Data, ID, Content> {
        MultiViewForEachIterator(content: self)
    }
}

@frozen
public struct MultiViewForEachIterator<
    Data: RandomAccessCollection,
    ID: Hashable,
    Content: View
>: MultiViewIterator {

    public var content: ForEach<Data, ID, Content>
    public init(content: ForEach<Data, ID, Content>) {
        self.content = content
    }

    public mutating func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        for value in content.data {
            let element = content.content(value)
            if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
                conformance.visit(content: element, visitor: visitor)
            } else {
                visitor.value.visit(element: element, context: .init())
            }
        }
    }
}
