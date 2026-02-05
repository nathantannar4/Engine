//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public protocol _AnyPropertyListKey {
    static var value: Any.Type { get }
}

struct PropertyList {
    struct ElementLayout<Fields> {
        var metadata: (Any.Type, UInt)
        var fields: Fields
    }

    struct ElementFieldsV1 {
        var keyType: Any.Type
        var before: UnsafeMutablePointer<ElementLayout<ElementFieldsV1>>?
        var after: UnsafeMutablePointer<ElementLayout<ElementFieldsV1>>?
        var length: Int
        var keyFilter: UInt
        var id: Int
    }

    struct ElementFieldsV6 {
        var keyType: Any.Type
        var before: UnsafeMutablePointer<ElementLayout<ElementFieldsV6>>?
        var after: UnsafeMutablePointer<ElementLayout<ElementFieldsV6>>?
        var skip: UnsafeMutablePointer<ElementLayout<ElementFieldsV6>>?
        var length: UInt32
        var skipCount: UInt32
        var keyFilter: UInt
        var id: Int
    }

    struct TypedElementLayout<Fields, Value> {
        var base: ElementLayout<Fields>
        var value: Value
    }

    enum ElementPointer {
        case v1(UnsafeMutablePointer<ElementLayout<ElementFieldsV1>>)
        case v6(UnsafeMutablePointer<ElementLayout<ElementFieldsV6>>)

        var object: Unmanaged<AnyObject> {
            switch self {
            case .v1(let ptr): Unmanaged<AnyObject>.fromOpaque(ptr)
            case .v6(let ptr): Unmanaged<AnyObject>.fromOpaque(ptr)
            }
        }

        var metadata: (Any.Type, UInt) {
            switch self {
            case .v1(let ptr): ptr.pointee.metadata
            case .v6(let ptr): ptr.pointee.metadata
            }
        }

        var fields: Any {
            switch self {
            case .v1(let ptr): ptr.pointee.fields
            case .v6(let ptr): ptr.pointee.fields
            }
        }

        var id: Int {
            switch self {
            case .v1(let ptr): ptr.pointee.fields.id
            case .v6(let ptr): ptr.pointee.fields.id
            }
        }

        var keyType: Any.Type {
            switch self {
            case .v1(let ptr): ptr.pointee.fields.keyType
            case .v6(let ptr): ptr.pointee.fields.keyType
            }
        }

        var after: ElementPointer? {
            get {
                switch self {
                case .v1(let ptr):
                    guard let after = ptr.pointee.fields.after else { return nil }
                    return .v1(after)
                case .v6(let ptr):
                    guard let after = ptr.pointee.fields.after else { return nil }
                    return .v6(after)
                }
            }
            nonmutating set {
                switch self {
                case .v1(let ptr):
                    if case .v1(let newValue) = newValue {
                        ptr.pointee.fields.after = newValue
                    } else {
                        ptr.pointee.fields.after = nil
                    }
                case .v6(let ptr):
                    if case .v6(let newValue) = newValue {
                        ptr.pointee.fields.after = newValue
                    } else {
                        ptr.pointee.fields.after = nil
                    }
                }
            }
        }

        var skip: ElementPointer? {
            get {
                switch self {
                case .v1:
                    return nil
                case .v6(let ptr):
                    guard let skip = ptr.pointee.fields.skip else { return nil }
                    return .v6(skip)
                }
            }
            nonmutating set {
                switch self {
                case .v1:
                    break
                case .v6(let ptr):
                    if case .v6(let newValue) = newValue {
                        ptr.pointee.fields.skip = newValue
                    } else {
                        ptr.pointee.fields.skip = nil
                    }
                }
            }
        }

        var skipCount: UInt32 {
            get {
                switch self {
                case .v1:
                    return 0
                case .v6(let ptr):
                    return ptr.pointee.fields.skipCount
                }
            }
            nonmutating set {
                switch self {
                case .v1:
                    break
                case .v6(let ptr):
                    ptr.pointee.fields.skipCount = newValue
                }
            }
        }

        var keyFilter: UInt {
            get {
                switch self {
                case .v1(let ptr): ptr.pointee.fields.keyFilter
                case .v6(let ptr): ptr.pointee.fields.keyFilter
                }
            }
            nonmutating set {
                switch self {
                case .v1(let ptr):
                    ptr.pointee.fields.keyFilter = newValue
                case .v6(let ptr):
                    ptr.pointee.fields.keyFilter = newValue
                }
            }
        }

        var length: UInt32 {
            get {
                switch self {
                case .v1(let ptr): UInt32(ptr.pointee.fields.length)
                case .v6(let ptr): ptr.pointee.fields.length
                }
            }
            nonmutating set {
                switch self {
                case .v1(let ptr):
                    ptr.pointee.fields.length = Int(newValue)
                case .v6(let ptr):
                    ptr.pointee.fields.length = newValue
                }
            }
        }

        var valueType: Any.Type? {
            // Engine
            if let keyType = keyType as? _AnyPropertyListKey.Type {
                return keyType.value
            }
            // SwiftUI
            let object = object.takeUnretainedValue()
            let type = try? swift_getFieldType("value", object)
            return type
        }

        var value: Any {
            guard let valueType = valueType else {
                return Mirror(reflecting: object.takeUnretainedValue()).descendant("value") as Any
            }
            func project<T>(_: T.Type) -> Any {
                getValue(T.self)
            }
            return _openExistential(valueType, do: project)
        }

        func value<T>(as _: T.Type) -> T? {
            let value = value
            let valueType = type(of: value)
            if T.self == valueType || T.self == Any.self {
                return value as? T
            } else if swift_getSize(of: valueType) >= MemoryLayout<T>.size {
                func project<Value>(_ value: Value) -> T {
                    unsafeBitCast(value, to: T.self)
                }
                return _openExistential(value, do: project)
            }
            return nil
        }

        func setValue<T>(
            _ newValue: T
        ) {
            precondition(valueType == T.self)
            switch self {
            case .v1(let ptr):
                return ptr.withUnsafeValuePointer(T.self, fields: ElementFieldsV1.self) { ptr in
                    ptr.pointee.value = newValue
                }
            case .v6(let ptr):
                return ptr.withUnsafeValuePointer(T.self, fields: ElementFieldsV6.self) { ptr in
                    ptr.pointee.value = newValue
                }
            }
        }

        private func getValue<T>(
            _ type: T.Type
        ) -> T {
            switch self {
            case .v1(let ptr):
                return ptr.withUnsafeValuePointer(T.self, fields: ElementFieldsV1.self) { ptr in
                    return ptr.pointee.value
                }
            case .v6(let ptr):
                return ptr.withUnsafeValuePointer(T.self, fields: ElementFieldsV6.self) { ptr in
                    return ptr.pointee.value
                }
            }
        }
    }

    var ptr: UnsafeMutableRawPointer?

    var elements: ElementPointer? {
        guard let ptr else { return nil }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return .v6(
                ptr.assumingMemoryBound(to: ElementLayout<ElementFieldsV6>.self)
            )
        } else {
            return .v1(
                ptr.assumingMemoryBound(to: ElementLayout<ElementFieldsV1>.self)
            )
        }
    }

    func value<Input, Value>(
        _ : Input.Type,
        as: Value.Type
    ) -> Value? {
        var ptr = elements
        while let p = ptr {
            if p.keyType == Input.self {
                return p.value(as: Value.self)
            }
            ptr = p.after
        }
        return nil
    }

    func value<Value>(
        key: String,
        as: Value.Type
    ) -> Value? {
        var ptr = elements
        while let p = ptr {
            let typeName = _typeName(p.keyType, qualified: false)
            if typeName == key {
                return p.value(as: Value.self)
            }
            ptr = p.after
        }
        return nil
    }

    mutating func set<Value>(
        _ key: String,
        _ newValue: Value
    ) {
        var ptr = elements
        while let p = ptr {
            let typeName = _typeName(p.keyType, qualified: false)
            if typeName == key {
                if p.valueType == Value.self {
                    p.setValue(newValue)
                }
                return
            }
            ptr = p.after
        }
    }

    mutating func add<Input, Value>(
        _ input: Input.Type,
        _ newValue: Value
    ) {
        guard let lastValue = ptr else {
            return
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            let lastValue = lastValue.assumingMemoryBound(to: ElementLayout<ElementFieldsV6>.self)
            let newValue = TypedElementLayout<ElementFieldsV6, Value>(
                base: ElementLayout(
                    metadata: lastValue.pointee.metadata, // Fake a class type of the last value
                    fields: ElementFieldsV6(
                        keyType: Input.self,
                        before: nil,
                        after: lastValue,
                        skip: lastValue.pointee.fields.skip,
                        length: lastValue.pointee.fields.length + 1,
                        skipCount: lastValue.pointee.fields.skip != nil ? lastValue.pointee.fields.skipCount + 1 : 0,
                        keyFilter: lastValue.pointee.fields.keyFilter, // Unknown purpose
                        id: UniqueID.generate()
                    )
                ),
                value: newValue
            )
            let ref = UnsafeMutablePointer<TypedElementLayout<ElementFieldsV6, Value>>.allocate(capacity: 1)
            ref.initialize(to: newValue)
            ptr = UnsafeMutableRawPointer(ref)
        } else {
            let lastValue = lastValue.assumingMemoryBound(to: ElementLayout<ElementFieldsV1>.self)
            let newValue = TypedElementLayout<ElementFieldsV1, Value>(
                base: ElementLayout(
                    metadata: lastValue.pointee.metadata, // Fake a class type of the last value
                    fields: ElementFieldsV1(
                        keyType: Input.self,
                        before: nil,
                        after: lastValue,
                        length: lastValue.pointee.fields.length + 1,
                        keyFilter: lastValue.pointee.fields.keyFilter, // Unknown purpose
                        id: UniqueID.generate()
                    )
                ),
                value: newValue
            )
            let ref = UnsafeMutablePointer<TypedElementLayout<ElementFieldsV1, Value>>.allocate(capacity: 1)
            ref.initialize(to: newValue)
            ptr = UnsafeMutableRawPointer(ref)
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { value(Input.self, as: Input.Value.self) ?? Input.defaultValue }
        set { add(Input.self, newValue) }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { value(Input.self, as: Input.Value.self) }
        set { add(Input.self, newValue ?? Input.defaultValue) }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type
    ) -> Value? {
        get { value(key: key, as: Value.self) }
    }

    public subscript<Value>(
        key: String
    ) -> Value? {
        get { value(key: key, as: Value.self) }
        set {
            if let newValue {
                set(key, newValue)
            } else {
                assertionFailure("Elements cannot be removed from a PropertyList")
            }
        }
    }
}

extension UnsafeMutablePointer {

    func withUnsafeValuePointer<Fields, T, ReturnType>(
        _ type: T.Type,
        fields: Fields.Type,
        do body: (UnsafeMutablePointer<PropertyList.TypedElementLayout<Fields, T>>) -> ReturnType
    ) -> ReturnType where Pointee == PropertyList.ElementLayout<Fields> {
        withMemoryRebound(to: PropertyList.TypedElementLayout<Fields, T>.self, capacity: 1) { p in
            return body(&p.pointee)
        }
    }
}

private struct UniqueID {
    private nonisolated(unsafe) static let lock: os_unfair_lock_t = {
        let lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock_s())
        return lock
    }()
    private nonisolated(unsafe) static var seed: Int = .max

    static func generate() -> Int {
        defer {
            os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(Self.lock) }
            seed -= 1
            if seed < 0 {
                seed = .max
            }
        }
        return seed
    }
}
