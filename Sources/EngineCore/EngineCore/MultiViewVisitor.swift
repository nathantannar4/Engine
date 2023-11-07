//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``MultiViewVisitor`` allows for an opaque collection of
/// `some View` to be unwrapped to visit the concrete `View` element.
public protocol MultiViewVisitor {
    mutating func visit<Content: View>(content: Content, context: Context, stop: inout Bool)

    typealias Context = MultiViewElementContext
}

@frozen
public struct MultiViewElementContext {

    public struct ID: Hashable {

        private indirect enum Storage: Hashable {
            case root(TypeIdentifier)
            case subview(Storage, TypeIdentifier)
            case offset(Storage, AnyHashable)
        }
        private var storage: Storage

        init<Content: View>(_: Content.Type) {
            self.storage = .root(TypeIdentifier(Content.self))
        }

        mutating func append<Content: View>(_: Content.Type) {
            storage = .subview(storage, TypeIdentifier(Content.self))
        }

        mutating func append<Offset: Hashable>(offset: Offset) {
            storage = .offset(storage, AnyHashable(offset))
        }
    }

    public struct Traits: OptionSet {
        public var rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let header = Traits(rawValue: 1 << 0)
        public static let footer = Traits(rawValue: 1 << 1)
    }

    public var id: ID
    public var traits: Traits

    init(context: MultiViewIteratorContext) {
        self.traits = context.traits
        self.id = context.id
    }
}

private struct MultiViewVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: MultiViewVisitor.Type
    var context: MultiViewIteratorContext
    var stop: Bool
}

@_silgen_name("c_visit_MultiView")
func c_visit_MultiView(
    _ content: UnsafeRawPointer,
    _ visitor: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ conformance: UnsafeRawPointer,
    _ descriptor: UnsafeRawPointer
)

/// A protocol that defines views with children that can be iterated
public protocol MultiView: View {

    associatedtype Iterator: MultiViewIterator
    func makeSubviewIterator() -> Iterator
}

public protocol MultiViewIterator {
    mutating func visit<Visitor: MultiViewVisitor>(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    )

    typealias Context = MultiViewIteratorContext
}

public struct MultiViewIteratorContext {

    var traits: MultiViewElementContext.Traits
    var modifier: Any?
    var id: MultiViewElementContext.ID

    public init<Content: View>(_: Content.Type = Content.self) {
        self.traits = []
        self.modifier = nil
        self.id = .init(Content.self)
    }

    public func union(_ traits: MultiViewElementContext.Traits) -> Self {
        var copy = self
        copy.traits.formUnion(traits)
        return copy
    }

    public func modifier<Modifier: ViewModifier>(_ modifier: Modifier) -> Self {
        var copy = self
        guard let m = self.modifier else {
            copy.modifier = modifier
            return copy
        }
        func project<M>(_ m: M) -> Any {
            let conformance = ViewModifierProtocolDescriptor.conformance(of: M.self)!
            var visitor = MultiViewIteratorContextModifierVisitor(
                existing: m,
                inserting: modifier
            )
            conformance.visit(visitor: &visitor)
            return visitor.output!
        }
        copy.modifier = _openExistential(m, do: project)
        return copy
    }
}

extension MultiView {

    /// Unwraps the type to be visited by the `Visitor`
    @inline(__always)
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var stop = false
        visit(visitor: visitor, stop: &stop)
    }

    /// Unwraps the type to be visited by the `Visitor`
    @inline(__always)
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        stop: inout Bool
    ) {
        visit(visitor: visitor, context: .init(Self.self), stop: &stop)
    }

    @inlinable
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: MultiViewIteratorContext,
        stop: inout Bool
    ) {
        var iterator = makeSubviewIterator()
        iterator.visit(visitor: visitor, context: context, stop: &stop)
    }
}

extension ProtocolConformance where P == MultiViewProtocolDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<
        Content: View,
        Visitor: MultiViewVisitor
    >(
        content: Content,
        visitor: UnsafeMutablePointer<Visitor>,
        context: MultiViewIteratorContext,
        stop: inout Bool
    ) {
        precondition(unsafeBitCast(Content.self, to: UnsafeRawPointer.self) == metadata)
        var context = MultiViewVisitorContext(
            visitor: visitor,
            type: Visitor.self,
            context: context,
            stop: stop
        )
        withUnsafePointer(to: content) { content in
            withUnsafeMutablePointer(to: &context) {
                c_visit_MultiView(content, $0, metadata, conformance, P.descriptor)
            }
        }
        stop = context.stop
    }
}

/// The ``TypeDescriptor`` for the ``MultiView`` protocol
public struct MultiViewProtocolDescriptor: TypeDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _MultiViewProtocolDescriptor()
    }
}

@_silgen_name("_MultiViewProtocolDescriptor")
func _MultiViewProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_MultiView")
public func _swift_visit_MultiView<Content: MultiView>(
    _ content: UnsafeRawPointer,
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: MultiViewVisitorContext.self)
    func project<Visitor: MultiViewVisitor>(type: Visitor.Type) {
        let visitor = c.value.visitor.assumingMemoryBound(to: Visitor.self)
        let content = content.assumingMemoryBound(to: Content.self)
        content.pointee.visit(
            visitor: visitor,
            context: c.pointee.context,
            stop: &c.pointee.stop
        )
    }
    _openExistential(c.value.type, do: project)
}

extension MultiViewVisitor {
    public mutating func visit<Content: View>(
        content: Content,
        context: MultiViewIteratorContext,
        stop: inout Bool
    ) {
        var context = context
        context.id.append(Content.self)
        if let modifier = context.modifier {
            stop = withUnsafeMutablePointer(to: &self) { ptr in
                func project<Modifier>(_ modifier: Modifier) -> Bool {
                    let conformance = ViewModifierProtocolDescriptor.conformance(of: Modifier.self)!
                    var visitor = MultiViewIteratorModifierVisitor(
                        content: content,
                        modifier: modifier,
                        context: context,
                        visitor: ptr
                    )
                    conformance.visit(visitor: &visitor)
                    return visitor.stop
                }
                return _openExistential(modifier, do: project)
            }
        } else {
            visit(content: content, context: .init(context: context), stop: &stop)
        }
    }
}

private struct MultiViewIteratorModifierVisitor<
    Content: View,
    M,
    Visitor: MultiViewVisitor
>: ViewModifierVisitor {

    var content: Content
    var modifier: M
    var context: MultiViewIteratorContext
    var visitor: UnsafeMutablePointer<Visitor>
    var stop = false

    mutating func visit<Modifier: ViewModifier>(type: Modifier.Type) {
        let modifier = unsafeBitCast(modifier, to: Modifier.self)
        visitor.pointee.visit(
            content: content.modifier(modifier),
            context: .init(context: context),
            stop: &stop
        )
    }
}

private struct MultiViewIteratorContextModifierVisitor<M, N: ViewModifier>: ViewModifierVisitor {
    var existing: M
    var inserting: N
    var output: Any!

    mutating func visit<Modifier: ViewModifier>(type: Modifier.Type) {
        let existing = unsafeBitCast(existing, to: Modifier.self)
        output = inserting.concat(existing)
    }
}
