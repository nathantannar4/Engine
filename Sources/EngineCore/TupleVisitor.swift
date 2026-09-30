//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``TupleVisitor`` allows for a tuple to be unwrapped
/// to visit the concrete type for each index.
///
/// > Tip: `stop` will be `true` on the last element visited
///
public protocol TupleVisitor {
    /// Visits the element of the tuple.
    ///
    /// - Parameters:
    ///   - element: The element being visited.
    ///   - offset: The memory offset of the element within the tuple.
    ///   - stop: Set to `true` to stop visiting any remaining elements.
    mutating func visit<Element>(element: Element, offset: Offset, stop: inout Bool)

    /// The memory offset of `Element`
    typealias Offset = Int
}

/// A type metadata enforced wrapper for a tuple
@frozen
public struct Tuple<Values> {

    /// The wrapped tuple.
    public var values: Values

    /// The number of elements in the tuple.
    public var count: Int {
        Self.count
    }

    /// The number of elements in the tuple type.
    public static var count: Int {
        let metadata = Metadata<TupleMetadata>(Values.self)!
        return metadata[\.numberOfElements]
    }

    /// Wraps the tuple, or returns `nil` if `Values` is not a tuple type.
    public init?(_ values: Values) {
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

    /// Unwraps the elements to be visited by the `Visitor`
    public func visit<Visitor: TupleVisitor>(
        visitor: UnsafeMutablePointer<Visitor>,
        stop: inout Bool
    ) {
        let metadata = Metadata<TupleMetadata>(Values.self)!
        let elements = metadata[\.elements]
        for index in elements.indices {
            let element = elements[index]
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
            stop = index == elements.count - 1
            _openExistential(element.type, do: project)
            guard !stop else { return }
        }
    }
}
