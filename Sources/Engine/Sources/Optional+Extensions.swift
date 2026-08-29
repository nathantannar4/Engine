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

    @usableFromInline
    var isNotNone: Bool {
        get { self != nil }
        set {
            if !newValue {
                self = .none
            }
        }
    }

    @usableFromInline
    subscript(defaultValue: Wrapped) -> Wrapped where Wrapped: Hashable {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return wrapped
            }
        }
        set {
            self = .some(newValue)
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

    @usableFromInline
    subscript(defaultValue: String) -> String {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return wrapped
            }
        }
        set {
            self = .some(newValue)
        }
    }
}

extension Optional where Wrapped == Int {

    @usableFromInline
    var value: String {
        get {
            switch self {
            case .none:
                return ""
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = newValue.isEmpty ? .none : Int(newValue)
        }
    }

    @usableFromInline
    subscript(defaultValue: String) -> String {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = Int(newValue)
        }
    }
}

extension Optional where Wrapped == Double {

    @usableFromInline
    var value: String {
        get {
            switch self {
            case .none:
                return ""
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = newValue.isEmpty ? .none : Double(newValue)
        }
    }

    @usableFromInline
    subscript(defaultValue: String) -> String {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = Double(newValue)
        }
    }
}

extension Optional where Wrapped == Float {

    @usableFromInline
    var value: String {
        get {
            switch self {
            case .none:
                return ""
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = newValue.isEmpty ? .none : Float(newValue)
        }
    }

    @usableFromInline
    subscript(defaultValue: String) -> String {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return String(wrapped)
            }
        }
        set {
            self = Float(newValue)
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

    @usableFromInline
    subscript(defaultValue: String) -> String {
        get {
            switch self {
            case .none:
                return defaultValue
            case .some(let wrapped):
                return wrapped.absoluteString
            }
        }
        set {
            self = URL(string: newValue)
        }
    }
}

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
