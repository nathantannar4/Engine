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
        } else if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.Body.self) {
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
    }
}

extension View {

    public func visit<
        Visitor: ViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        #if os(iOS) || os(tvOS)
        if let conformance = UIViewRepresentableProtocolDescriptor.conformance(of: Self.self) {
            conformance.visit(visitor: visitor)
        } else if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Self.self) {
            conformance.visit(visitor: visitor)
        } else {
            visitor.pointee.visit(type: Self.self)
        }
        #elseif os(macOS)
        if let conformance = NSViewRepresentableProtocolDescriptor.conformance(of: Self.self) {
            conformance.visit(visitor: visitor)
        } else if let conformance = NSViewControllerRepresentableProtocolDescriptor.conformance(of: Self.self) {
            conformance.visit(visitor: visitor)
        } else {
            visitor.pointee.visit(type: Self.self)
        }
        #endif
    }

    public func makeSubviewIterator() -> some MultiViewIterator {
        CustomViewIterator(content: self)
    }

    @_disfavoredOverload
    @inline(__always)
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var stop = false
        visit(visitor: visitor, stop: &stop)
    }

    @_disfavoredOverload
    @inline(__always)
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        stop: inout Bool
    ) {
        visit(visitor: visitor, context: .init(Self.self), stop: &stop)
    }

    @_disfavoredOverload
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: MultiViewIteratorContext,
        stop: inout Bool
    ) {
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Self.self) {
            conformance.visit(
                content: self,
                visitor: visitor,
                context: context,
                stop: &stop
            )
        } else {
            let iterator = CustomViewIterator(content: self)
            iterator.visit(
                visitor: visitor,
                context: context,
                stop: &stop
            )
        }
    }
}
