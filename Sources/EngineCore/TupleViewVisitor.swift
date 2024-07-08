//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension TupleView: MultiView {
    public func makeSubviewIterator() -> some MultiViewIterator {
        TupleSubviewIterator(content: value)
    }
}

private struct TupleSubviewIterator<
    Content
>: MultiViewIterator {

    enum Storage {
        case content(Content)
        case tuple(Tuple<Content>)
    }

    var storage: Storage

    init(content: Content) {
        self.storage = Tuple(content).map { .tuple($0) } ?? .content(content)
    }

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        switch storage {
        case .content(let content):
            if let conformance = ViewProtocolDescriptor.conformance(of: Content.self) {
                var visitor = TupleSubviewIteratorViewVisitor(
                    element: content,
                    visitor: visitor,
                    context: context
                )
                conformance.visit(visitor: &visitor)
            }

        case .tuple(let tuple):
            var vistor = TupleSubviewIteratorElementVisitor(
                visitor: visitor,
                context: context
            )
            tuple.visit(visitor: &vistor, stop: &stop)
        }
    }
}

private struct TupleSubviewIteratorElementVisitor<
    Visitor: MultiViewVisitor
>: TupleVisitor {

    var visitor: UnsafeMutablePointer<Visitor>
    var context: MultiViewIteratorContext
    var index = 0

    mutating func visit<Element>(
        element: Element,
        offset: Offset,
        stop: inout Bool
    ) {
        if let conformance = ViewProtocolDescriptor.conformance(of: Element.self) {
            var context = context
            context.id.append(offset: index)
            var visitor = TupleSubviewIteratorViewVisitor(
                element: element,
                visitor: visitor,
                context: context
            )
            conformance.visit(visitor: &visitor)
            stop = visitor.stop
        }
        index += 1
    }
}

private struct TupleSubviewIteratorViewVisitor<
    Element,
    Visitor: MultiViewVisitor
>: ViewVisitor {

    var element: Element
    var visitor: UnsafeMutablePointer<Visitor>
    var context: MultiViewIteratorContext
    var stop = false

    mutating func visit<Content: View>(type: Content.Type) {
        let content = unsafeBitCast(element, to: Content.self)
        var context = context
        context.id.append(Content.self)
        content.visit(visitor: visitor, context: context, stop: &stop)
    }
}
