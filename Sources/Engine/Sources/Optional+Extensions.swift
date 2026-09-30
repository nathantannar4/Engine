//
// Copyright (c) Nathan Tannar
//

import Foundation

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

    @_disfavoredOverload
    @usableFromInline
    subscript(defaultValue: Subscript<Wrapped>) -> Wrapped {
        get {
            switch self {
            case .none:
                return defaultValue.value
            case .some(let wrapped):
                return wrapped
            }
        }
        set {
            self = .some(newValue)
        }
    }
}

/// A key path subscript argument for values that may not be `Hashable`.
///
/// Key paths are compared by their subscript arguments, and `Binding`s are compared
/// by their key paths. So `Subscript` compares by value where possible, so that a
/// `Binding` transformed with the same value is equal between view updates.
@usableFromInline
final class Subscript<Value>: Hashable {
    var value: Value

    @usableFromInline
    init(_ value: Value) {
        self.value = value
    }

    @usableFromInline
    static func == (lhs: Subscript<Value>, rhs: Subscript<Value>) -> Bool {
        if lhs === rhs {
            return true
        }
        if let lhsValue = lhs.value as? any Hashable {
            return lhsValue.isEqual(to: rhs.value)
        }
        if let lhsValue = lhs.value as? any Equatable {
            return lhsValue.isEqual(to: rhs.value)
        }
        if Value.self is AnyClass {
            return (lhs.value as AnyObject) === (rhs.value as AnyObject)
        }
        return false
    }

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        if let value = value as? any Hashable {
            hasher.combine(AnyHashable(value))
        } else if value is any Equatable {
            // Equal values must have equal hashes, and `Equatable` values
            // cannot be hashed, so rely on `==` to distinguish them
        } else if Value.self is AnyClass {
            hasher.combine(ObjectIdentifier(value as AnyObject))
        } else {
            hasher.combine(ObjectIdentifier(self))
        }
    }
}

extension Equatable {
    fileprivate func isEqual(to other: Any) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
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
