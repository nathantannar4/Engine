//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension ModifiedContent: MultiView where Content: View, Modifier: ViewModifier {

    public func makeSubviewIterator() -> some MultiViewIterator {
        ModifiedContentSubviewIterator(
            content: content,
            modifier: modifier
        )
    }
}

private struct ModifiedContentSubviewIterator<
    Content: View,
    Modifier: ViewModifier
>: MultiViewIterator {

    var content: Content
    var modifier: Modifier

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            conformance.visit(
                content: content,
                visitor: visitor,
                context: context.modifier(modifier),
                stop: &stop
            )
        } else {
            visitor.value.visit(
                content: content.modifier(modifier),
                context: context,
                stop: &stop
            )
        }
    }
}
