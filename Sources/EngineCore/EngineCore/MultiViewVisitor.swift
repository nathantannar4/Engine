//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``MultiViewVisitor`` allows for an opaque collection of
/// `some View` to be unwrapped to visit the concrete `View` element.
public protocol MultiViewVisitor {
    mutating func visit<Element: View>(element: Element, context: Context)

    #if os(iOS) || os(tvOS)
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Element: UIViewControllerRepresentable>(element: Element, context: Context)
    #endif

    #if os(macOS)
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    mutating func visit<Element: NSViewControllerRepresentable>(element: Element, context: Context)
    #endif

    typealias Context = _MultiViewVisitorContext
}

@frozen
public struct _MultiViewVisitorContext {

    @usableFromInline
    struct Flags: OptionSet {
        @usableFromInline
        var rawValue: UInt8

        @usableFromInline
        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static let null = Flags(rawValue: 1 << 0)
        static let header = Flags(rawValue: 1 << 1)
        static let footer = Flags(rawValue: 1 << 2)
    }

    @usableFromInline
    var flags: Flags

    @inlinable
    public init() {
        self.flags = Flags()
    }

    init(flags: Flags) {
        self.flags = flags
    }

    public var isNil: Bool { flags.contains(.null) }

    public var isHeader: Bool { flags.contains(.header) }

    public var isFooter: Bool { flags.contains(.footer) }
}

extension MultiViewVisitor {
    public mutating func visit<Element: View>(element: Element, context: Context) { }
}

struct MultiViewVisitorContext {
    var visitor: UnsafeMutableRawPointer
    var type: MultiViewVisitor.Type
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
public protocol MultiView {

    /// A tuple of multiple views, or any singular view
    associatedtype Subview
    
    associatedtype Index: Comparable = Int
    var startIndex: Index { get }
    var endIndex: Index { get }

    subscript(position: Index) -> Subview { get }

    associatedtype Iterator: MultiViewIterator
    func makeIterator() -> Iterator
}

public protocol MultiViewIterator {
    mutating func visit<Visitor: MultiViewVisitor>(visitor: UnsafeMutablePointer<Visitor>)
}

extension MultiView {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var iterator = makeIterator()
        iterator.visit(visitor: visitor)
    }

    public var subviews: [AnyView] {
        var visitor = MultiViewSubviewVisitor()
        visit(visitor: &visitor)
        return visitor.subviews
    }
}

extension ProtocolConformance where P == MultiViewProtocolDescriptor {

    /// Unwraps the type to be visited by the `Visitor`
    public func visit<
        Content: View,
        Visitor: MultiViewVisitor
    >(
        content: Content,
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        precondition(unsafeBitCast(Content.self, to: UnsafeRawPointer.self) == metadata)
        var ctx = MultiViewVisitorContext(visitor: visitor, type: Visitor.self)
        withUnsafePointer(to: content) { content in
            withUnsafeMutablePointer(to: &ctx) {
                c_visit_MultiView(content, $0, metadata, conformance, P.descriptor)
            }
        }
    }
}

/// The ``TypeDescriptor`` for the `MultiView` protocol
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
        content.pointee.visit(visitor: visitor)
    }
    _openExistential(c.value.type, do: project)
}

@frozen
public struct MultiViewSubviewIterator<Content>: MultiViewIterator {

    public var content: Content
    public init(content: Content) {
        self.content = content
    }

    public mutating func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        func project<Element>(_ element: Element) {
            visit(element: element, visitor: visitor)
        }

        if let count = swift_getTupleCount(content) {
            for index in 0..<count {
                let value = swift_getTupleElement(index, content)!
                _openExistential(value, do: project)
            }
        } else {
            project(content)
        }
    }

    private func visit<
        Element,
        Visitor: MultiViewVisitor
    >(
        element: Element,
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var visitor = TupleMultiViewElementVisitor(
            element: element,
            visitor: visitor
        )
        #if os(iOS) || os(tvOS)
        if let conformance = UIViewControllerRepresentableProtocolDescriptor.conformance(of: Element.self) {
            conformance.visit(visitor: &visitor)
        }
        #elseif os(macOS)
        if let conformance = NSViewControllerRepresentableProtocolDescriptor.conformance(of: Element.self) {
            conformance.visit(visitor: &visitor)
        }
        #endif
        if let conformance = ViewProtocolDescriptor.conformance(of: Element.self) {
            conformance.visit(visitor: &visitor)
        }
    }
}

private struct TupleMultiViewElementVisitor<
    Element,
    Visitor: MultiViewVisitor
>: ViewVisitor {

    var element: Element
    var visitor: UnsafeMutablePointer<Visitor>

    func visit<Content>(type: Content.Type) where Content: View {
        let element = unsafeBitCast(element, to: Content.self)
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Element.self) {
            conformance.visit(content: element, visitor: visitor)
        } else {
            visitor.value.visit(element: element, context: .init())
        }
    }

    #if os(iOS) || os(tvOS)
    mutating func visit<Content>(type: Content.Type) where Content: UIViewControllerRepresentable {
        let element = unsafeBitCast(element, to: Content.self)
        visitor.value.visit(element: element, context: .init())
    }
    #endif

    #if os(macOS)
    mutating func visit<Content>(type: Content.Type) where Content: NSViewControllerRepresentable {
        let element = unsafeBitCast(element, to: Content.self)
        visitor.value.visit(element: element, context: .init())
    }
    #endif
}

private struct MultiViewSubviewVisitor: MultiViewVisitor {
    var subviews: [AnyView] = []

    mutating func visit<Element: View>(element: Element, context: Context) {
        subviews.append(AnyView(element))
    }
}
