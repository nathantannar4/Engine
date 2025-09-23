//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `ViewModifier` that only modifies the static inputs
public protocol GraphInputsModifier: _GraphInputsModifier, ViewModifier where Body == Never {
    static nonisolated func makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs)
}

extension GraphInputsModifier {
    public nonisolated static func _makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        makeInputs(modifier: modifier, inputs: &inputs)
    }
}

private struct GraphInputsLayout {
    var customInputs: PropertyList
}

protocol _CustomInputsProvider { }

extension _CustomInputsProvider {

    var customInputs: PropertyList {
        get {
            withUnsafePointer(to: self) { ptr -> PropertyList in
                ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr -> PropertyList in
                    ptr.pointee.customInputs
                }
            }
        }
        set {
            withUnsafeMutablePointer(to: &self) { ptr in
                ptr.withMemoryRebound(to: GraphInputsLayout.self, capacity: 1) { ptr in
                    ptr.pointee.customInputs = newValue
                }
            }
        }
    }
}

extension _GraphInputs: _CustomInputsProvider {

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    public subscript<Value>(
        key: String,
        _: Value.Type
    ) -> Value? {
        get { customInputs[key, Value.self] }
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
            .modifier(UnaryViewModifier())
            .modifier(Modifier())
    }

    private struct Modifier: GraphInputsModifier {
        nonisolated static func makeInputs(
            modifier: _GraphValue<Self>,
            inputs: inout _GraphInputs
        ) {
            inputs.customInputs.detach()
        }
    }
}

extension PropertyList {
    fileprivate mutating func detach() {

        var ptr = elements
        let branchKey: String = ".ImplicitRootType"
        let containerKey = ".UIKitHostContainerFocusItemInput"
        var hasPassedContainer = false
        while let p = ptr {
            let key = _typeName(p.keyType, qualified: true)
            let isMatch = key.hasSuffix(branchKey)
                || (key.hasSuffix(".FocusedItemInputKey") && hasPassedContainer)
                || (key.hasSuffix(".ViewListOptionsInput") && hasPassedContainer)
            if isMatch {
                break
            }
            hasPassedContainer = hasPassedContainer || key.hasSuffix(containerKey)
            if let next = p.after {
                ptr = next
            } else {
                return
            }
        }

        let tail = ptr!
        var last = tail.after
        tail.after = nil

        while let p = last?.after {
            if let after = p.after {
                let key = _typeName(after.keyType, qualified: true)
                let isMatch = key.hasSuffix(branchKey)
                    || key.hasSuffix(".AccessibilityRelationshipScope")
                    || key.hasSuffix(".EventBindingBridgeFactoryInput")
                    || key.hasSuffix(".InterfaceIdiomInput")
                    || key.hasSuffix(containerKey)
                if isMatch {
                    break
                }
            }
            last = p
        }

        guard let last else { return }

        ptr = elements
        let offset = tail.length - (last.length + 1)
        while offset > 0, let p = ptr {
            if let skip = p.skip, skip.length < tail.length {
                p.skip = last
                p.skipCount = p.length - last.length - offset
            }
            p.length -= offset
            if p.skip == nil {
                p.skipCount = p.length
            }
            ptr = p.after
        }

        _ = last.object.retain() // Prevent dealloc
        tail.after = last
        if last.skip == nil {
            tail.skip = last
            tail.skipCount = 1
        }
    }
}
