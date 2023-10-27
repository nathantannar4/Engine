//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

@frozen
public struct ViewInputs {
    
    var inputs: _GraphInputs

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        inputs[Input.self]
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        inputs[Input.self]
    }
}

@frozen
public struct _ViewInputsLogModifier: ViewInputsModifier {

    @inlinable
    public init() { }

    public static func makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        let log: String = inputs.withCustomInputs { inputs in
            var message = "\n=== ViewInputs ===\n"
            var ptr = inputs.elements
            while let p = ptr {
                dump(p, to: &message)
                message += "  ▿ fields: \(dump(p.pointee.fields, to: &message))"
                func project<T>(_ type: T.Type) -> String {
                    return p.pointee.withUnsafeValuePointer(T.self) { ref in
                        return "  ▿ value: \(dump(ref.pointee.value))\n"
                    }
                }
                message += _openExistential(p.pointee.fields.keyType, do: project)
                ptr = p.pointee.fields.after
            }
            return message
        }
        os_log(.debug, "%@", log)
    }
}

/// Detaches the `_ViewInputs` from the previous renderer host, so that context sensitive
/// functionality is reset. SwiftUI's presentation modifiers seem to do something like this.
///
/// This fixes:
/// - Resetting SwiftUI view styles
/// - Resetting Engine view styles
/// - Resetting NavigationStack
@frozen
public struct _ViewInputsBridgeModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            ._defaultContext()
            .modifier(Modifier())
    }

    private struct Modifier: ViewInputsModifier {
        static func makeInputs(
            modifier: _GraphValue<Self>,
            inputs: inout _GraphInputs
        ) {
            inputs.withCustomInputs { customInputs in
                customInputs.detach()
            }
        }
    }
}

extension _GraphInputs {
    fileprivate var customInputs: CustomInputsLayout {
        withUnsafePointer(to: self) { ptr -> CustomInputsLayout in
            ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr -> CustomInputsLayout in
                ptr.pointee.customInputs
            }
        }
    }

    fileprivate mutating func withCustomInputs<ReturnType>(
        do body: (inout CustomInputsLayout) -> ReturnType
    ) -> ReturnType {
        withUnsafeMutablePointer(to: &self) { ptr -> ReturnType in
            ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr -> ReturnType in
                body(&ptr.pointee.customInputs)
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get {
            customInputs.value(Input.self) ?? Input.defaultValue
        }
        set {
            withCustomInputs {
                $0.add(Input.self, newValue)
            }
        }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get {
            customInputs.value(Input.self)
        }
        set {
            withCustomInputs {
                $0.add(Input.self, newValue ?? Input.defaultValue)
            }
        }
    }
}

private struct GraphInputsLayout {
    var customInputs: CustomInputsLayout
}

private struct CustomInputsLayout {
    struct ElementLayout {
        var metadata: (Any.Type, UInt)
        var fields: ElementFields

        mutating func withUnsafeValuePointer<T, ReturnType>(
            _ type: T.Type,
            do body: (UnsafeMutablePointer<CustomInputsLayout.TypedElementLayout<T>>) -> ReturnType
        ) -> ReturnType {
            withUnsafeMutablePointer(to: &self) { ptr -> ReturnType in
                ptr.withMemoryRebound(
                    to: CustomInputsLayout.TypedElementLayout<T>.self,
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

    mutating func detach() {
        var ptr = elements
        while let p = ptr {
            let key = _typeName(ptr!.pointee.fields.keyType, qualified: true)
            var isMatch = key.hasSuffix(".MatchedGeometryScope")
            #if !os(macOS)
            let branchKey: String
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                branchKey = "SwiftUI.UIKitHostContainerFocusItemInput"
            } else {
                branchKey = ".ImplicitRootType"
            }
            isMatch = isMatch || key.hasSuffix(branchKey)
            #endif
            if isMatch {
                // Reached the {UI/NS}ViewRepresentable
                #if !os(macOS)
                if let next = p.pointee.fields.after {
                    // Reached the UIViewRepresentable
                    if _typeName(next.pointee.fields.keyType, qualified: true).hasSuffix(branchKey) {
                        ptr = next
                    }
                }
                #endif
                break
            }
            if let next = p.pointee.fields.after {
                ptr = next
            } else {
                return
            }
        }

        let tail = ptr!
        var last = tail.pointee.fields.after
        tail.pointee.fields.after = nil
        while let p = last?.pointee.fields.after {
            last = p
        }

        ptr = elements
        let offset = tail.pointee.fields.length - (last == nil ? 1 : 2)
        while offset > 0, let p = ptr {
            p.pointee.fields.length -= offset
            ptr = p.pointee.fields.after
        }
        if let last {
            tail.pointee.fields.after = last
        }
    }

    func withUnsafeValuePointer<Input: ViewInputKey, ReturnType>(
        _ type: Input.Type,
        do body: (UnsafeMutablePointer<CustomInputsLayout.TypedElementLayout<Input.Value>>) -> ReturnType
    ) -> ReturnType? {
        var ptr: UnsafeMutablePointer<ElementLayout>? = elements
        while let p = ptr {
            if p.pointee.fields.keyType == Input.self {
                return p.pointee.withUnsafeValuePointer(Input.Value.self) { ptr in
                    body(ptr)
                }
            }
            ptr = p.pointee.fields.after
        }
        return nil
    }

    func value<Input: ViewInputKey>(_ : Input.Type) -> Input.Value? {
        withUnsafeValuePointer(Input.self) { ptr in
            ptr.pointee.value
        }
    }

    mutating func add<Input: ViewInputKey>(
        _ input: Input.Type,
        _ newValue: Input.Value
    ) {
        guard let lastValue = elements else {
            return
        }
        let newValue = TypedElementLayout<Input.Value>(
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
        let ref = UnsafeMutablePointer<TypedElementLayout<Input.Value>>.allocate(capacity: 1)
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

extension _ViewInputs {
    public var _graphInputs: _GraphInputs {
        @_transparent get {
            withUnsafePointer(to: self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee
                }
            }
        }
        @_transparent set {
            withUnsafeMutablePointer(to: &self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee = newValue
                }
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }
}

extension _ViewListInputs {
    public var _graphInputs: _GraphInputs {
        @_transparent get {
            withUnsafePointer(to: self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee
                }
            }
        }
        @_transparent set {
            withUnsafeMutablePointer(to: &self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee = newValue
                }
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs {
    public var _graphInputs: _GraphInputs {
        get {
            withUnsafePointer(to: self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee
                }
            }
        }
        set {
            withUnsafeMutablePointer(to: &self) { ptr in
                ptr.withMemoryRebound(to: _GraphInputs.self, capacity: 1) { ptr in
                    ptr.pointee = newValue
                }
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        @_transparent get { _graphInputs[Input.self] }
        @_transparent set { _graphInputs[Input.self] = newValue }
    }
}
