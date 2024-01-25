//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
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
        #if DEBUG
        let log: String = inputs.withCustomInputs { inputs in
            var message = "\n=== ViewInputs ===\n"
            var ptr = inputs.elements
            while let p = ptr {
                dump(p, to: &message)
                dump(p.pointee.fields, to: &message)
                func project<T>(_ type: T.Type) {
                    p.pointee.withUnsafeValuePointer(T.self) { ref in
                        let value = ref.pointee.value
                        var valueString = ""
                        dump(value, to: &valueString)
                        message += "  ▿ value: \(valueString)\n"
                        let fields = swift_getFields(value)
                        for (field, value) in fields {
                            func _project<P>(_ type: P.Type) {
                                message += "    - \(field.key): \(value as! P)\n"
                            }
                            _openExistential(field.type, do: _project)
                        }
                    }
                }
                _openExistential(p.pointee.fields.keyType, do: project)
                ptr = p.pointee.fields.after
            }
            return message
        }
        os_log(.debug, "%@", log)
        #endif
    }
}

/// Detaches the `_ViewInputs` from the previous renderer host, so that context sensitive
/// functionality is reset. SwiftUI's presentation modifiers seem to do something like this.
///
/// This fixes:
/// - Resetting SwiftUI view styles
/// - Resetting Engine view styles
/// - Resetting Context (such as NavigationStack)
@frozen
public struct _ViewInputsBridgeModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
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
    fileprivate var customInputs: PropertyList {
        withUnsafePointer(to: self) { ptr -> PropertyList in
            ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr -> PropertyList in
                ptr.pointee.customInputs
            }
        }
    }

    fileprivate mutating func withCustomInputs<ReturnType>(
        do body: (inout PropertyList) -> ReturnType
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
            customInputs.value(Input.self, as: Input.Value.self) ?? Input.defaultValue
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
            customInputs.value(Input.self, as: Input.Value.self)
        }
        set {
            withCustomInputs {
                $0.add(Input.self, newValue ?? Input.defaultValue)
            }
        }
    }
}

private struct GraphInputsLayout {
    var customInputs: PropertyList
}

extension PropertyList {
    fileprivate mutating func detach() {
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
            _ = Unmanaged<AnyObject>.fromOpaque(last).retain() // Prevent dealloc
            tail.pointee.fields.after = last
        }
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
