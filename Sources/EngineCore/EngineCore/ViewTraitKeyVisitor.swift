//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``ViewTraitKeyVisitor`` allows for `some _ViewTraitKey` to be unwrapped
/// to visit the concrete `_ViewTraitKey` type.
public protocol ViewTraitKeyVisitor {
    mutating func visit<Key: _ViewTraitKey>(type: Key.Type)
}

struct ViewTraitKeyVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: ViewTraitKeyVisitor.Type
}

@_silgen_name("c_visit_ViewTraitKey")
func c_visit_ViewTraitKey(
    _ visitor: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ conformance: UnsafeRawPointer
)

extension ProtocolConformance where P == ViewTraitKeyProtocolDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<Visitor: ViewTraitKeyVisitor>(visitor: UnsafeMutablePointer<Visitor>) {
        var ctx = ViewTraitKeyVisitorContext(visitor: visitor, type: Visitor.self)
        withUnsafeMutablePointer(to: &ctx) {
            c_visit_ViewTraitKey($0, metadata, conformance)
        }
    }
}

/// The ``TypeDescriptor`` for the `_ViewTraitKey` protocol
public struct ViewTraitKeyProtocolDescriptor: TypeDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _ViewTraitKeyProtocolDescriptor()
    }
}

@_silgen_name("_ViewTraitKeyProtocolDescriptor")
func _ViewTraitKeyProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_ViewTraitKey")
public func _swift_visit_ViewTraitKey<Key: _ViewTraitKey>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Key.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewTraitKeyVisitorContext.self)
    func project<Visitor: ViewTraitKeyVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Key.self)
    }
    _openExistential(c.value.type, do: project)
}
