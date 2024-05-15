//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Section: MultiView where Parent: View, Content: View, Footer: View {

    public var parent: Parent {
        try! swift_getFieldValue("header", Parent.self, self)
    }

    public var content: Content {
        try! swift_getFieldValue("content", Content.self, self)
    }

    public var footer: Footer {
        try! swift_getFieldValue("footer", Footer.self, self)
    }

    public func makeSubviewIterator() -> some MultiViewIterator {
        SectionSubviewIterator(content: self)
    }
}


private struct SectionSubviewIterator<
    Parent: View,
    Content: View,
    Footer: View
>: MultiViewIterator {

    var content: Section<Parent, Content, Footer>

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        var context = context
        context.traits = []
        var headerContext = context.union(.header)
        headerContext.id.append(offset: 0)
        visitor.value.visit(
            content: content.parent,
            context: headerContext,
            stop: &stop
        )
        guard !stop else { return }
        var contentContext = context
        contentContext.id.append(offset: 1)
        content.content.visit(
            visitor: visitor,
            context: contentContext,
            stop: &stop
        )
        guard !stop else { return }
        var footerContext = context.union(.footer)
        footerContext.id.append(offset: 2)
        visitor.value.visit(
            content: content.footer,
            context: footerContext,
            stop: &stop
        )
    }
}
