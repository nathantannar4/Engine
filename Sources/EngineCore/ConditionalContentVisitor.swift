//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension _ConditionalContent: MultiView where TrueContent: View, FalseContent: View {

    public func makeSubviewIterator() -> some MultiViewIterator {
        ConditionalContentSubviewIterator(content: unsafeBitCast(self, to: _Storage.self))
    }

    enum _Storage {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }
}

private struct ConditionalContentSubviewIterator<
    TrueContent: View,
    FalseContent: View
>: MultiViewIterator {

    var content: _ConditionalContent<TrueContent, FalseContent>._Storage

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        var context = context
        switch content {
        case .trueContent(let trueContent):
            context.id.append(TrueContent.self)
            trueContent.visit(visitor: visitor, context: context, stop: &stop)
        case .falseContent(let falseContent):
            context.id.append(FalseContent.self)
            falseContent.visit(visitor: visitor, context: context, stop: &stop)
        }
    }
}
