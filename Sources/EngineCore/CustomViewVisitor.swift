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
        if context.traits.contains(.header) || context.traits.contains(.footer) {
            visitor.value.visit(
                content: content,
                context: context,
                stop: &stop
            )
        } else if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            conformance.visit(
                content: content,
                visitor: visitor,
                context: context,
                stop: &stop
            )
        } else if Content.Body.self != Never.self,
            let conformance = MultiViewProtocolDescriptor.conformance(of: Content.Body.self),
            !content.hasDynamicProperties
        {
            let body = content.getBody()
            if IsMultiViewVisitor.isMultiView(
                body, 
                conformance: conformance
            ) {
                var context = context
                if isOpaqueViewAnyView() {
                    context.id.append(Content.Body.self)
                }
                conformance.visit(
                    content: body,
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
    public nonisolated func makeSubviewIterator() -> some MultiViewIterator {
        CustomViewIterator(content: self)
    }

    nonisolated var hasDynamicProperties: Bool {
        let fields = swift_getFields(self)
        for field in fields {
            guard let value = field.value else { continue }
            func project<Value>(_ value: Value) -> Bool {
                value is DynamicProperty
            }
            let isDynamicProperty = _openExistential(value, do: project)
            if isDynamicProperty {
                return true
            }
        }
        return false
    }

    nonisolated func getBody() -> Body {
        let copy = SendableView(content: self)
        if Thread.isMainThread {
            return MainActor.assumeIsolated { [copy] in
                SendableView(content: copy.content.body)
            }.content
        }
        var body: SendableView<Body>!
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            body = SendableView(content: copy.content.body)
            semaphore.signal()
        }
        semaphore.wait()
        return body.content
    }
}

private struct SendableView<Content: View>: @unchecked Sendable {
    var content: Content
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
