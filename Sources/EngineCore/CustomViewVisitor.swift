//
// Copyright (c) Nathan Tannar
//

import SwiftUI

private struct CustomViewIterator<
    Content: View
>: MultiViewIterator {

    var content: Content

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
                context: context,
                stop: &stop
            )
        } else if Content.Body.self != Never.self,
            let conformance = MultiViewProtocolDescriptor.conformance(of: Content.Body.self)
        {
            let body = content.body
            if IsMultiViewVisitor.isMultiView(
                body, 
                conformance: conformance
            ) {
                var context = context
                // SwiftUI v6 wraps in AnyView
                var isAnyView = false
                #if DEBUG
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                    isAnyView = true
                }
                #endif
                if !isAnyView {
                    context.id.append(Content.Body.self)
                }
                conformance.visit(
                    content: content.body,
                    visitor: visitor,
                    context: context,
                    stop: &stop
                )
            } else {
                visitor.value.visit(
                    content: content,
                    context: context,
                    stop: &stop
                )
            }
        } else {
            visitor.value.visit(
                content: content,
                context: context,
                stop: &stop
            )
        }
    }
}

extension View {
    public func makeSubviewIterator() -> some MultiViewIterator {
        CustomViewIterator(content: self)
    }
}

private struct IsMultiViewVisitor: MultiViewVisitor {
    var count = 0

    mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        count += 1
        stop = count > 1
    }

    static func isMultiView<Content: View>(
        _ content: Content,
        conformance: ProtocolConformance<MultiViewProtocolDescriptor>
    ) -> Bool {
        var visitor = IsMultiViewVisitor()
        var stop = false
        conformance.visit(
            content: content,
            visitor: &visitor,
            context: .init(Content.self),
            stop: &stop
        )
        return visitor.count != 1
    }
}
