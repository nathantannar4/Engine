//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public func swift_getTupleCount<InstanceType>(_ instance: InstanceType) -> Int? {
    guard let metadata = Metadata<TupleMetadata>(InstanceType.self)
    else {
        return nil
    }

    return metadata[\.numberOfElements]
}

public func swift_getTupleElement<InstanceType>(_ index: Int, _ instance: InstanceType) -> Any? {
    guard let metadata = Metadata<TupleMetadata>(InstanceType.self)
    else {
        return nil
    }

    let element = metadata[\.elements][index]
    func project<Element>(_: Element.Type) -> Element {
        withUnsafePointer(to: instance) { pointer in
            UnsafeRawPointer(pointer)
                .advanced(by: element.offset)
                .assumingMemoryBound(to: Element.self)
                .pointee
        }
    }
    return _openExistential(element.type, do: project)
}

/// A ``TupleVisitor`` allows for a tuple to be unwrapped
/// to visit the concrete type for each index
protocol TupleVisitor {
    mutating func visit<Element>(type: Element.Type, offset: Offset)

    typealias Offset = TupleMetadata.Element.Layout.Offset
}

extension Metadata where Kind == TupleMetadata {

    /// Unwraps the elements to be visited by the `Visitor`
    func visit<Visitor: TupleVisitor>(visitor: UnsafeMutablePointer<Visitor>) {
        for element in self[\.elements] {
            func project<Element>(_: Element.Type) {
                visitor.value.visit(type: Element.self, offset: element.offset)
            }
            _openExistential(element.type, do: project)
        }
    }
}
