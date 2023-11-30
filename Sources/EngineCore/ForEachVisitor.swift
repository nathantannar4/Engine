//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension ForEach: MultiView where Content: View {

    public func makeSubviewIterator() -> some MultiViewIterator {
        ForEachSubviewIterator(content: self)
    }
}


private struct ForEachSubviewIterator<
    Data: RandomAccessCollection,
    ID: Hashable,
    Content: View
>: MultiViewIterator {

    var content: ForEach<Data, ID, Content>

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        let offset: (Data.Index) -> AnyHashable
        if let idGenerator = try? swift_getFieldValue("idGenerator", Any.self, self),
           let keyPath = Mirror(reflecting: idGenerator).children.first?.value as? KeyPath<Data.Element, ID>
        {
            offset = { index in
                content.data[index][keyPath: keyPath]
            }
        } else {
            var counter = 0
            offset = { index in
                if let index = index as? AnyHashable {
                    return index
                } else {
                    defer { counter += 1 }
                    return AnyHashable(counter)
                }
            }
        }
        for index in content.data.indices {
            let element = content.content(content.data[index])
            var context = context
            context.id.append(offset: offset(index))
            element.visit(
                visitor: visitor,
                context: context,
                stop: &stop
            )
            guard !stop else { return }
        }
    }
}
