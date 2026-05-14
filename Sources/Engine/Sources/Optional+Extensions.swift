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

extension Optional where Wrapped == String {

    @usableFromInline
    var value: String {
        get {
            switch self {
            case .none:
                return ""
            case .some(let wrapped):
                return wrapped
            }
        }
        set {
            self = newValue.isEmpty ? .none : .some(newValue)
        }
    }
}

extension Optional where Wrapped == Bool {

    @usableFromInline
    var isTrue: Bool {
        get {
            switch self {
            case .none:
                return false
            case .some(let wrapped):
                return wrapped
            }
        }
        set {
            self = .some(newValue)
        }
    }

    @usableFromInline
    var isFalse: Bool {
        get {
            switch self {
            case .none:
                return false
            case .some(let wrapped):
                return wrapped == false
            }
        }
        set {
            self = .some(!newValue)
        }
    }
}

extension Optional where Wrapped == URL {

    @usableFromInline
    var value: String {
        get {
            switch self {
            case .none:
                return ""
            case .some(let wrapped):
                return wrapped.absoluteString
            }
        }
        set {
            self = URL(string: newValue)
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
