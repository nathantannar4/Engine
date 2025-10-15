//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Optional {

    @usableFromInline
    var isNone: Bool {
        get { self == nil }
        set {
            if newValue {
                self = .none
            }
        }
    }
}

extension Optional {

    @usableFromInline
    var isNotNone: Bool {
        get { self != nil }
        set {
            if !newValue {
                self = .none
            }
        }
    }
}

extension Hashable {

    @usableFromInline
    var optional: Optional<Self> {
        Optional.some(self)
    }
}

@inlinable
func unwrap<each Value>(
    _ values: repeat (each Value)?
) -> (repeat each Value)? {
    for value in repeat (each values) {
        if case .none = value {
            return nil
        }
    }
    return (repeat (each values)!)
}
