//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// An ``EnvironmentKeyVisitor`` allows for `some _EnvironmentKey` to be unwrapped
/// to visit the concrete `EnvironmentKey` type.
public protocol EnvironmentKeyVisitor {
    mutating func visit<Key: EnvironmentKey>(type: Key.Type)
}

private struct EnvironmentKeyVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: EnvironmentKeyVisitor.Type
}

@_silgen_name("c_visit_EnvironmentKey")
func c_visit_EnvironmentKey(
    _ visitor: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ conformance: UnsafeRawPointer
)

extension ProtocolConformance where P == EnvironmentKeyProtocolDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<Visitor: EnvironmentKeyVisitor>(visitor: UnsafeMutablePointer<Visitor>) {
        var ctx = EnvironmentKeyVisitorContext(visitor: visitor, type: Visitor.self)
        withUnsafeMutablePointer(to: &ctx) {
            c_visit_EnvironmentKey($0, metadata, conformance)
        }
    }
}

/// The ``TypeDescriptor`` for the `EnvironmentKey` protocol
public struct EnvironmentKeyProtocolDescriptor: TypeDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _EnvironmentKeyProtocolDescriptor()
    }
}

@_silgen_name("_EnvironmentKeyProtocolDescriptor")
func _EnvironmentKeyProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_EnvironmentKey")
public func _swift_visit_EnvironmentKey<Key: EnvironmentKey>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Key.Type
) {
    let c = visitor.assumingMemoryBound(to: EnvironmentKeyVisitorContext.self)
    func project<Visitor: EnvironmentKeyVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Key.self)
    }
    _openExistential(c.value.type, do: project)
}
