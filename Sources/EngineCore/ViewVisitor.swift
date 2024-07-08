//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``ViewVisitor`` allows for `some View` to be unwrapped
/// to visit the concrete `View` type.
public protocol ViewVisitor {
    mutating func visit<Content: View>(type: Content.Type)

    #if os(iOS) || os(tvOS)
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: UIViewRepresentable>(type: Content.Type)

    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: UIViewControllerRepresentable>(type: Content.Type)
    #endif

    #if os(macOS)
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: NSViewRepresentable>(type: Content.Type)

    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Content: NSViewControllerRepresentable>(type: Content.Type)
    #endif
}

extension ViewVisitor {
    public func visit<Content: View>(type: Content.Type) { }
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
}

private struct ViewVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: ViewVisitor.Type
}

@_silgen_name("c_visit_View")
func c_visit_View(
    _ visitor: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ conformance: UnsafeRawPointer,
    _ descriptor: UnsafeRawPointer
)

extension ProtocolConformance where P: ViewProtocolConformanceDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<
        Visitor: ViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var ctx = ViewVisitorContext(visitor: visitor, type: Visitor.self)
        withUnsafeMutablePointer(to: &ctx) {
            c_visit_View($0, metadata, conformance, P.descriptor)
        }
    }
}

/// A protocol for `View` conformance ``TypeDescriptor``s
public protocol ViewProtocolConformanceDescriptor: TypeDescriptor { }

/// The ``TypeDescriptor`` for the `View` protocol
public struct ViewProtocolDescriptor: ViewProtocolConformanceDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _ViewProtocolDescriptor()
    }
}

@_silgen_name("_ViewProtocolDescriptor")
func _ViewProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_View")
public func _swift_visit_View<Content: View>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewVisitorContext.self)
    func project<Visitor: ViewVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Content.self)
    }
    _openExistential(c.value.type, do: project)
}

#if os(iOS) || os(tvOS)

/// The ``TypeDescriptor`` for the `UIViewRepresentable` protocol
public struct UIViewRepresentableProtocolDescriptor: ViewProtocolConformanceDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _UIViewRepresentableProtocolDescriptor()
    }
}

@_silgen_name("_UIViewRepresentableProtocolDescriptor")
func _UIViewRepresentableProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_UIViewRepresentable")
public func _swift_visit_UIViewRepresentable<Content: UIViewRepresentable>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewVisitorContext.self)
    func project<Visitor: ViewVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Content.self)
    }
    _openExistential(c.value.type, do: project)
}

/// The ``TypeDescriptor`` for the `UIViewControllerRepresentable` protocol
public struct UIViewControllerRepresentableProtocolDescriptor: ViewProtocolConformanceDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _UIViewControllerRepresentableProtocolDescriptor()
    }
}

@_silgen_name("_UIViewControllerRepresentableProtocolDescriptor")
func _UIViewControllerRepresentableProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_UIViewControllerRepresentable")
public func _swift_visit_UIViewControllerRepresentable<Content: UIViewControllerRepresentable>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewVisitorContext.self)
    func project<Visitor: ViewVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Content.self)
    }
    _openExistential(c.value.type, do: project)
}

#endif

#if os(macOS)

/// The ``TypeDescriptor`` for the `NSViewRepresentable` protocol
public struct NSViewRepresentableProtocolDescriptor: ViewProtocolConformanceDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _NSViewRepresentableProtocolDescriptor()
    }
}

@_silgen_name("_NSViewRepresentableProtocolDescriptor")
func _NSViewRepresentableProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_NSViewRepresentable")
public func _swift_visit_NSViewRepresentable<Content: NSViewRepresentable>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewVisitorContext.self)
    func project<Visitor: ViewVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Content.self)
    }
    _openExistential(c.value.type, do: project)
}

/// The ``TypeDescriptor`` for the `NSViewControllerRepresentable` protocol
public struct NSViewControllerRepresentableProtocolDescriptor: ViewProtocolConformanceDescriptor {
    public static var descriptor: UnsafeRawPointer {
        _NSViewControllerRepresentableProtocolDescriptor()
    }
}

@_silgen_name("_NSViewControllerRepresentableProtocolDescriptor")
func _NSViewControllerRepresentableProtocolDescriptor() -> UnsafeRawPointer

@_silgen_name("_swift_visit_NSViewControllerRepresentable")
public func _swift_visit_NSViewControllerRepresentable<Content: NSViewControllerRepresentable>(
    _ visitor: UnsafeMutableRawPointer,
    _ type: Content.Type
) {
    let c = visitor.assumingMemoryBound(to: ViewVisitorContext.self)
    func project<Visitor: ViewVisitor>(type: Visitor.Type) {
        c.value.visitor.assumingMemoryBound(to: Visitor.self).value.visit(type: Content.self)
    }
    _openExistential(c.value.type, do: project)
}

#endif
