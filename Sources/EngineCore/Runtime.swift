//
// Copyright (c) Nathan Tannar
//

import Foundation

@inline(__always)
public func isOpaqueViewAnyView() -> Bool {
    #if DEBUG && canImport(SwiftUICore)
    // Default build flag SWIFT_ENABLE_OPAQUE_TYPE_ERASURE via SDK check
    return c_swift_isOpaqueTypeErasureEnabled();
    #else
    return false
    #endif
}

public struct MetadataField {
    public let key: String
    public let type: Any.Type
}

public func swift_getFields<InstanceType>(_ instance: InstanceType) -> [(field: MetadataField, value: Any?)] {
    func unwrap<T>(_ x: Any) -> T {
        return x as! T
    }
    var fields = [(field: MetadataField, value: Any?)]()
    var mirror: Mirror? = Mirror(reflecting: instance)
    while let m = mirror {
        let nextValue = m.children.compactMap({ child -> (field: MetadataField, value: Any?)? in
            guard let key = child.label else {
                return nil
            }
            return (MetadataField(key: key, type: type(of: child.value)), unwrap(child.value))
        })
        fields.append(contentsOf: nextValue)
        mirror = m.superclassMirror
    }
    return fields
}

public func swift_getFieldValue<Value, InstanceType>(_ key: String, _ value: Value.Type, _ instance: InstanceType) throws -> Value {
    try getFieldValue(key, value, instance)
}

public func swift_getFieldValue<Value, InstanceType>(_ key: String, _ value: Value.Type, _ instance: InstanceType?) throws -> Value? {
    guard let instance else {
        return nil
    }
    return try getFieldValue(key, value, instance)
}

public func swift_setFieldValue<Value, InstanceType>(_ key: String, _ value: Value, _ instance: inout InstanceType) throws {
    try setFieldValue(key, value, &instance)
}

public func swift_setFieldValue<Value, InstanceType>(_ key: String, _ value: Value, _ instance: inout InstanceType?) throws {
    guard instance != nil else { return }
    try setFieldValue(key, value, &instance!)
}

public func swift_setFieldValue<Value, InstanceType: AnyObject>(_ key: String, _ value: Value, _ instance: InstanceType) throws {
    var instance = instance
    try setFieldValue(key, value, &instance)
}

public func swift_setFieldValue<Value, InstanceType: AnyObject>(_ key: String, _ value: Value, _ instance: InstanceType?) throws {
    guard var instance else { return }
    try setFieldValue(key, value, &instance)
}

public func swift_getStructGenerics(for type: Any.Type) -> [Any.Type]? {
    guard let metadata = Metadata<StructMetadata>(type) else {
        return nil
    }
    return metadata[\.genericTypes]
}

public func swift_getClassGenerics(for type: Any.Type) -> [Any.Type]? {
    guard let metadata = Metadata<ClassMetadata>(type) else {
        return nil
    }
    return metadata[\.genericTypes]
}

public func swift_getIsClassType(_ type: Any.Type) -> Bool {
    return c_swift_isClassType(type)
}

public func swift_getIsClassType(_ instance: Any) -> Bool {
    return c_swift_isClassType(type(of: instance))
}

public func swift_getMangledTypeName(of type: Any.Type) -> String? {
    guard let namePtr = swift_getMangledTypeName(type) else { return nil }
    return String(cString: namePtr)
}

struct SwiftFieldNotFoundError: Error, CustomStringConvertible {
    var key: String
    var instance: Any.Type

    var description: String {
        "\(key) was not found on instance type \(instance)"
    }
}

struct SwiftFieldTypeMismatchError: Error, CustomStringConvertible {
    var key: String
    var expected: Any.Type
    var received: Any.Type
    var instance: Any.Type

    var description: String {
        "Expected type of \(expected) for key \(key) but recieved \(received) on instance type \(instance)"
    }
}

private func getFieldValue<Value, InstanceType>(
    _ key: String,
    _ value: Value.Type,
    _ instance: InstanceType
) throws -> Value {
    let field = try swift_getField(key, instance)
    guard MemoryLayout<Value>.size == swift_getSize(of: field.type) || value == Any.self else {
        throw SwiftFieldTypeMismatchError(
            key: key,
            expected: field.type,
            received: value,
            instance: type(of: instance)
        )
    }
    return try withUnsafeInstancePointer(instance) { pointer in
        func project<S>(_ type: S.Type) -> Value {
            let buffer = pointer.advanced(by: field.offset).assumingMemoryBound(to: S.self)
            if value == Any.self {
                let box = buffer.pointee as Any
                return box as! Value
            }
            return unsafeBitCast(buffer.pointee, to: value)
        }
        return _openExistential(field.type, do: project)
    }
}

private func setFieldValue<Value, InstanceType>(
    _ key: String,
    _ value: Value,
    _ instance: inout InstanceType
) throws {
    let instanceType = type(of: instance)
    let field = try swift_getField(key, instance)
    guard MemoryLayout<Value>.size == swift_getSize(of: field.type) || Value.self == Any.self else {
        throw SwiftFieldTypeMismatchError(
            key: key,
            expected: field.type,
            received: Value.self,
            instance: instanceType
        )
    }
    try withUnsafeMutableInstancePointer(&instance) { pointer in
        func project<S>(_: S.Type) throws {
            let buffer = pointer.advanced(by: field.offset).assumingMemoryBound(to: S.self)
            if Value.self == Any.self {
                guard let value = value as? S else {
                    throw SwiftFieldTypeMismatchError(
                        key: key,
                        expected: field.type,
                        received: Any.self,
                        instance: instanceType
                    )
                }
                buffer.pointee = value
            } else {
                buffer.pointee = unsafeBitCast(value, to: S.self)
            }
        }
        try _openExistential(field.type, do: project)
    }
}

private class FieldLookupCache {

    private let lock: os_unfair_lock_t
    private var storage = [UnsafeRawPointer: [String: Field]]()

    static let shared = FieldLookupCache()
    private init() {
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock_s())
    }

    subscript(type: Any.Type, key: String) -> Field? {
        get {
            storage[unsafeBitCast(type, to: UnsafeRawPointer.self)]?[key]
        }
        set {
            os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(lock) }
            storage[unsafeBitCast(type, to: UnsafeRawPointer.self), default: [:]][key] = newValue
        }
    }
}

private func swift_getField(
    _ key: String,
    _ instance: Any
) throws -> Field {
    var type: Any.Type = type(of: instance)
    if type == Any.self {
        func project<T>(_: T) -> Any.Type {
            return T.self
        }
        type = _openExistential(instance, do: project)
    }
    if let field = FieldLookupCache.shared[type, key] {
        return field
    }
    do {
        let field = try swift_getField_slow(key, type)
        FieldLookupCache.shared[type, key] = field
        return field
    } catch {
        throw error
    }
}

private func swift_getField_slow(
    _ key: String,
    _ instanceType: Any.Type
) throws -> Field {
    let count = swift_reflectionMirror_recursiveCount(instanceType)
    for i in 0..<count {
        var field = FieldReflectionMetadata()
        let fieldType = swift_reflectionMirror_recursiveChildMetadata(instanceType, index: i, fieldMetadata: &field)
        defer { field.dealloc?(field.name) }
        guard
            let name = field.name.map({ String(utf8String: $0) }),
            name == key
        else {
            continue
        }
        let offset = swift_reflectionMirror_recursiveChildOffset(instanceType, index: i)
        return Field(type: fieldType, offset: offset)
    }
    throw SwiftFieldNotFoundError(key: key, instance: instanceType)
}

private func withUnsafeInstancePointer<InstanceType, Result>(
    _ instance: InstanceType,
    _ body: (UnsafeRawPointer) throws -> Result
) throws -> Result {
    if c_swift_isClassType(InstanceType.self) {
        return try withUnsafePointer(to: instance) {
            try $0.withMemoryRebound(to: UnsafeRawPointer.self, capacity: 1) {
                try body($0.pointee)
            }
        }
    } else {
        return try withUnsafePointer(to: instance) {
            let ptr = UnsafeRawPointer($0)
            return try body(ptr)
        }
    }
}

private func withUnsafeMutableInstancePointer<InstanceType, Result>(
    _ instance: inout InstanceType,
    _ body: (UnsafeMutableRawPointer) throws -> Result
) throws -> Result {
    if c_swift_isClassType(InstanceType.self) {
        return try withUnsafeMutablePointer(to: &instance) {
            try $0.withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) {
                try body($0.pointee)
            }
        }
    } else {
        return try withUnsafeMutablePointer(to: &instance) {
            let ptr = UnsafeMutableRawPointer(mutating: $0)
            return try body(ptr)
        }
    }
}

private func swift_getSize(of type: Any.Type) -> Int {
    func project<T>(_: T.Type) -> Int {
        MemoryLayout<T>.size
    }
    return _openExistential(type, do: project)
}

private struct Field {
    let type: Any.Type
    let offset: Int
}

private typealias Dealloc = @convention(c) (UnsafePointer<CChar>?) -> Void

private struct FieldReflectionMetadata {
    let name: UnsafePointer<CChar>? = nil
    let dealloc: Dealloc? = nil
    let isStrong: Bool = false
    let isVar: Bool = false
}

@_silgen_name("c_swift_isClassType")
private func c_swift_isClassType(_: Any.Type) -> Bool

@_silgen_name("swift_reflectionMirror_recursiveCount")
private func swift_reflectionMirror_recursiveCount(_: Any.Type) -> Int

@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
private func swift_reflectionMirror_recursiveChildMetadata(
    _: Any.Type
    , index: Int
    , fieldMetadata: UnsafeMutablePointer<FieldReflectionMetadata>
) -> Any.Type

@_silgen_name("swift_reflectionMirror_recursiveChildOffset")
private func swift_reflectionMirror_recursiveChildOffset(_: Any.Type, index: Int) -> Int

@_silgen_name("swift_getMangledTypeName")
private func swift_getMangledTypeName(_ type: Any.Type) -> UnsafePointer<CChar>?

@_silgen_name("c_swift_isOpaqueTypeErasureEnabled")
private func c_swift_isOpaqueTypeErasureEnabled() -> Bool
