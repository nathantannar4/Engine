//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group: MultiView where Content: View {

    public var content: Content {
        try! swift_getFieldValue("content", Content.self, self)
    }

    public func makeSubviewIterator() -> some MultiViewIterator {
        GroupSubviewIterator(content: self)
    }
}

private struct GroupSubviewIterator<
    Content: View
>: MultiViewIterator {

    var content: Group<Content>

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        var context = context
        context.id.append(Content.self)
        content.content.visit(visitor: visitor, context: context, stop: &stop)
    }
}
