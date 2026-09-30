//
// Copyright (c) Nathan Tannar
//

import Foundation

extension Equatable {

    @usableFromInline
    var optional: Optional<Self> {
        get { Optional.some(self) }
        set {
            if case .some(let wrapped) = newValue {
                self = wrapped
            }
        }
    }
}

/// A tuple of `Equatable` elements that is itself `Equatable`.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@frozen
public struct EquatableTuple<each Element: Equatable>: Equatable {
    /// The elements of the tuple.
    public var elements: (repeat each Element)

    /// Creates a tuple from the given elements.
    public init(_ elements: repeat each Element) {
        self.elements = (repeat each elements)
    }

    public static func == (lhs: EquatableTuple, rhs: EquatableTuple) -> Bool {
        for (l, r) in repeat (each lhs.elements, each rhs.elements) {
            if l != r { return false }
        }
        return true
    }
}
