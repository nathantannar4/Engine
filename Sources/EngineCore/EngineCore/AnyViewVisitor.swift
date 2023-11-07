//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension AnyView {

    /// Creates a type-erased view from a type-erased value if that value is also a `View`
    @_disfavoredOverload
    public init?(visiting content: Any) {
        func project<T>(_ value: T) -> AnyView? {
            guard let conformance = ViewProtocolDescriptor.conformance(of: T.self) else {
                return nil
            }
            var visitor = AnyViewVisitor(input: value)
            conformance.visit(visitor: &visitor)
            return visitor.output
        }
        guard let view = _openExistential(content, do: project) else {
            return nil
        }
        self = view
    }
}

private struct AnyViewVisitor<Input>: ViewVisitor {
    var input: Input
    var output: AnyView!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        output = AnyView(unsafeBitCast(input, to: Content.self))
    }
}

extension AnyView: MultiView {
    public func makeSubviewIterator() -> some MultiViewIterator {
        AnyViewSubviewIterator(content: self)
    }
}

private struct AnyViewSubviewIterator: MultiViewIterator {

    var content: AnyView

    mutating func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        func project<Storage>(_ storage: Storage) throws -> Bool {
            func project<Value>(_ value: Value) -> Bool {
                let conformance = ViewProtocolDescriptor.conformance(of: Value.self)!
                var visitor = AnyViewStorageVisitor(
                    value: value,
                    visitor: visitor,
                    context: context
                )
                conformance.visit(visitor: &visitor)
                return visitor.stop
            }
            let view = try swift_getFieldValue("view", Any.self, storage)
            return _openExistential(view, do: project)
        }
        do {
            let storage = try swift_getFieldValue("storage", Any.self, content)
            stop = try _openExistential(storage, do: project)
        } catch { }
    }
}

private struct AnyViewStorageVisitor<
    Value,
    Visitor: MultiViewVisitor
>: ViewVisitor {

    var value: Value
    var visitor: UnsafeMutablePointer<Visitor>
    var context: MultiViewIteratorContext
    var stop = false

    mutating func visit<Content: View>(type: Content.Type) {
        let content = unsafeBitCast(value, to: Content.self)
        content.visit(visitor: visitor, context: context, stop: &stop)
    }
}
