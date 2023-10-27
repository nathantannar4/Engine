//
// Copyright (c) Nathan Tannar
//

import Foundation

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

public func swift_getFieldValue<Value, InstanceType>(_ key: String, _ type: Value.Type, _ instance: InstanceType) throws -> Value {
    try getFieldValue(key, type, instance)
}

public func swift_setFieldValue<Value, ObjectType: AnyObject>(_ key: String, _ value: Value, _ object: ObjectType) throws {
    var instance = object
    try setFieldValue(key, value, &instance)
}

@_disfavoredOverload
public func swift_setFieldValue<Value, InstanceType>(_ key: String, _ value: Value, _ instance: inout InstanceType) throws {
    try setFieldValue(key, value, &instance)
}

struct SwiftFieldNotFoundError: Error, CustomStringConvertible {
    var type: Any.Type
    var key: String
    var instance: Any.Type

    var description: String {
        "\(key) of type \(String(describing: type)) was not found on instance type \(instance)"
    }
}

private func getFieldValue<Value, InstanceType>(
    _ key: String,
    _ type: Value.Type,
    _ instance: InstanceType
) throws -> Value {
    let field = try swift_getField(key, type, Swift.type(of: instance))
    return try withUnsafeInstancePointer(instance) { pointer in
        func project<S>(_ type: S.Type) -> Value {
            pointer.advanced(by: field.offset).withMemoryRebound(to: S.self, capacity: 1) { ptr in
                unsafePartialBitCast(ptr.pointee, to: Value.self)
            }
        }
        return _openExistential(field.type, do: project)
    }
}

private func setFieldValue<Value, InstanceType>(
    _ key: String,
    _ value: Value,
    _ instance: inout InstanceType
) throws {
    let field = try swift_getField(key, Value.self, Swift.type(of: instance))
    try withUnsafeMutableInstancePointer(&instance) { pointer in
        func project<S>(_ type: S.Type) {
            let buffer = pointer.advanced(by: field.offset).assumingMemoryBound(to: S.self)
            withUnsafePointer(to: value) { ptr in
                ptr.withMemoryRebound(to: S.self, capacity: 1) { ptr in
                    buffer.pointee = ptr.pointee
                }
            }
        }
        _openExistential(field.type, do: project)
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

private func swift_getField<Value>(
    _ key: String,
    _ type: Value.Type,
    _ instanceType: Any.Type
) throws -> Field {

    if let field = FieldLookupCache.shared[type, key] {
        return field
    }
    do {
        let field = try swift_getField_slow(key, type, instanceType)
        FieldLookupCache.shared[type, key] = field
        return field
    } catch {
        throw error
    }
}

private func swift_getField_slow<Value>(
    _ key: String,
    _ type: Value.Type,
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

        if fieldType != type {
            func getTypeSize<FieldType>(type: FieldType) -> Int {
                MemoryLayout<FieldType>.size
            }
            let fieldSize = _openExistential(fieldType, do: getTypeSize)
            let valueSize = MemoryLayout<Value>.size
            guard valueSize <= fieldSize else {
                break
            }
        }

        let offset = swift_reflectionMirror_recursiveChildOffset(instanceType, index: i)
        return Field(type: fieldType, offset: offset)
    }
    throw SwiftFieldNotFoundError(type: Value.self, key: key, instance: instanceType)
}

private func withUnsafeInstancePointer<InstanceType, Result>(
    _ instance: InstanceType,
    _ body: (UnsafeRawPointer) throws -> Result
) throws -> Result {
    if swift_isClassType(InstanceType.self) {
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
    if swift_isClassType(InstanceType.self) {
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

@_silgen_name("swift_isClassType")
private func swift_isClassType(_: Any.Type) -> Bool

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
