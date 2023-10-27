//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``ViewModifierVisitor`` allows for `some ViewModifier` to be unwrapped
/// to visit the concrete `ViewModifier` type.
public protocol ViewModifierVisitor {
    mutating func visit<Modifier: ViewModifier>(type: Modifier.Type)
}

struct ViewModifierVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: ViewModifierVisitor.Type
}

@_silgen_name("c_visit_ViewModifier")
func c_visit_ViewModifier(
    _ visitor: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ conformance: UnsafeRawPointer
)

extension ProtocolConformance where P == ViewModifierProtocolDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<Visitor: ViewModifierVisitor>(visitor: UnsafeMutablePointer<Visitor>) {
        var ctx = ViewModifierVisitorContext(visitor: visitor, type: Visitor.self)
        withUnsafeMutablePointer(to: &ctx) {
            c_visit_ViewModifier($0, metadata, conformance)
        }
    }
}

/// The ``TypeDescriptor`` for the `ViewModifier` protocol
public struct ViewModifierProtocolDescriptor: TypeDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _ViewModifierProtocolDescriptor()
    }
}

@_silgen_name("_ViewModifierProtocolDescriptor")
func _ViewModifierProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_ViewModifier")
public func _swift_visit_ViewModifier<Modifier: ViewModifier>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Modifier.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewModifierVisitorContext.self)
    func project<Visitor: ViewModifierVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Modifier.self)
    }
    _openExistential(c.value.type, do: project)
}
