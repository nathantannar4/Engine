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

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@frozen
public struct EquatableTuple<each Element: Equatable>: Equatable {
    public var elements: (repeat each Element)

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
