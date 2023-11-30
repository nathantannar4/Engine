//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``TupleVisitor`` allows for a tuple to be unwrapped
/// to visit the concrete type for each index
public protocol TupleVisitor {
    mutating func visit<Element>(element: Element, offset: Offset, stop: inout Bool)

    typealias Offset = Int
}

/// A type metadata enforced wrapper for a tuple
@frozen
public struct Tuple<Values> {

    public var values: Values

    public var count: Int {
        let metadata = Metadata<TupleMetadata>(Values.self)!
        return metadata[\.numberOfElements]
    }

    init?(_ values: Values) {
        let descriptor = unsafeBitCast(Values.self, to: UnsafeRawPointer.self)
        guard MetadataKind(ptr: descriptor) == .tuple else {
            return nil
        }
        self.values = values
    }

    /// Unwraps the elements to be visited by the `Visitor`
    @inline(__always)
    public func visit<Visitor: TupleVisitor>(
        visitor: UnsafeMutablePointer<Visitor>
    ) {
        var stop = false
        visit(visitor: visitor, stop: &stop)
    }

    public func visit<Visitor: TupleVisitor>(
        visitor: UnsafeMutablePointer<Visitor>,
        stop: inout Bool
    ) {
        let metadata = Metadata<TupleMetadata>(Values.self)!
        for element in metadata[\.elements] {
            func project<Element>(_: Element.Type) {
                withUnsafePointer(to: values) { ptr in
                    UnsafeRawPointer(ptr)
                        .advanced(by: element.offset)
                        .withMemoryRebound(to: Element.self, capacity: 1) { ptr in
                            visitor.value.visit(
                                element: ptr.pointee,
                                offset: element.offset,
                                stop: &stop
                            )
                        }
                }
            }
            _openExistential(element.type, do: project)
            guard !stop else { return }
        }
    }
}
