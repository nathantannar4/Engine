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

        do {
            var headerContext = context.union(.header)
            headerContext.id.append(offset: 0)
            headerContext.id.append(Parent.self)

            var isEmptyVisitor = MultiViewIsEmptyVisitor()
            content.parent.visit(visitor: &isEmptyVisitor)

            if isEmptyVisitor.isEmpty == false {
                visitor.value.visit(
                    content: content.parent,
                    context: headerContext,
                    stop: &stop
                )
            }
        }

        guard !stop else { return }

        do {
            var contentContext = context
            contentContext.id.append(offset: 1)
            contentContext.id.append(Content.self)
            content.content.visit(
                visitor: visitor,
                context: contentContext,
                stop: &stop
            )
        }

        guard !stop else { return }

        do {
            var footerContext = context.union(.footer)
            footerContext.id.append(offset: 2)
            footerContext.id.append(Footer.self)

            var isEmptyVisitor = MultiViewIsEmptyVisitor()
            content.footer.visit(visitor: &isEmptyVisitor)

            if isEmptyVisitor.isEmpty == false {
                visitor.value.visit(
                    content: content.footer,
                    context: footerContext,
                    stop: &stop
                )
            }
        }
    }
}

private struct MultiViewIsEmptyVisitor: MultiViewVisitor {

    public private(set) var isEmpty: Bool = true

    @inlinable
    public init() { }

    public mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        isEmpty = false
        stop = true
    }
}
