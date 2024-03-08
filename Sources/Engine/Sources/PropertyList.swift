//
// Copyright (c) Nathan Tannar
//

import SwiftUI

struct PropertyList {
    struct ElementLayout {
        var metadata: (Any.Type, UInt)
        var fields: ElementFields

        mutating func withUnsafeValuePointer<T, ReturnType>(
            _ type: T.Type,
            do body: (UnsafeMutablePointer<PropertyList.TypedElementLayout<T>>) -> ReturnType
        ) -> ReturnType {
            withUnsafeMutablePointer(to: &self) { ptr -> ReturnType in
                ptr.withMemoryRebound(
                    to: PropertyList.TypedElementLayout<T>.self,
                    capacity: 1,
                    body
                )
            }
        }
    }

    struct ElementFields {
        var keyType: Any.Type
        var before: UnsafeMutablePointer<ElementLayout>?
        var after: UnsafeMutablePointer<ElementLayout>?
        var length: Int
        var keyFilter: UInt
        var id: UInt
    }

    struct TypedElementLayout<Value> {
        var base: ElementLayout
        var value: Value
    }

    var elements: UnsafeMutablePointer<ElementLayout>?

    func withUnsafeValuePointer<Input, Value, ReturnType>(
        _ : Input.Type,
        as: Value.Type,
        do body: (UnsafeMutablePointer<PropertyList.TypedElementLayout<Value>>) -> ReturnType
    ) -> ReturnType? {
        var ptr: UnsafeMutablePointer<ElementLayout>? = elements
        while let p = ptr {
            if p.pointee.fields.keyType == Input.self {
                return p.pointee.withUnsafeValuePointer(Value.self) { ptr in
                    body(ptr)
                }
            }
            ptr = p.pointee.fields.after
        }
        return nil
    }

    func withUnsafeValuePointer<Value, ReturnType>(
        key: String,
        as: Value.Type,
        do body: (UnsafeMutablePointer<PropertyList.TypedElementLayout<Value>>) -> ReturnType
    ) -> ReturnType? {
        var ptr: UnsafeMutablePointer<ElementLayout>? = elements
        while let p = ptr {
            let typeName = _typeName(p.pointee.fields.keyType, qualified: false)
            if typeName == key {
                return p.pointee.withUnsafeValuePointer(Value.self) { ptr in
                    body(ptr)
                }
            }
            ptr = p.pointee.fields.after
        }
        return nil
    }

    func value<Input, Value>(_ : Input.Type, as: Value.Type) -> Value? {
        withUnsafeValuePointer(Input.self, as: Value.self) { ptr in
            ptr.pointee.value
        }
    }

    mutating func add<Input, Value>(
        _ input: Input.Type,
        _ newValue: Value
    ) {
        guard let lastValue = elements else {
            return
        }
        let newValue = TypedElementLayout<Value>(
            base: ElementLayout(
                metadata: lastValue.pointee.metadata,
                fields: .init(
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
        let ref = UnsafeMutablePointer<TypedElementLayout<Value>>.allocate(capacity: 1)
        ref.initialize(to: newValue)
        elements = UnsafeMutableRawPointer(ref).assumingMemoryBound(to: ElementLayout.self)
    }
}

private struct UniqueID {
    private static var seed: UInt = .max

    static func generate() -> UInt {
        defer { seed = seed &- 1 }
        return seed
    }
}
