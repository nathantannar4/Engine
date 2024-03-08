//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `ViewModifier` that only modifies the static inputs
public protocol GraphInputsModifier: _GraphInputsModifier, ViewModifier where Body == Never {
    static func makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs)
}

extension GraphInputsModifier {
    public static func _makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        makeInputs(modifier: modifier, inputs: &inputs)
    }
}

private struct GraphInputsLayout {
    var customInputs: PropertyList
}

extension _GraphInputs {
    var customInputs: PropertyList {
        withUnsafePointer(to: self) { ptr -> PropertyList in
            ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr -> PropertyList in
                ptr.pointee.customInputs
            }
        }
    }

    mutating func withCustomInputs<ReturnType>(
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

    public subscript<Value>(
        key: String,
        _: Value.Type
    ) -> Value? {
        customInputs.withUnsafeValuePointer(key: key, as: Value.self) { ptr in
            ptr.pointee.value
        }
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

    private struct Modifier: GraphInputsModifier {
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
