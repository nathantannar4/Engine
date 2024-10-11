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
        customInputs.value(key: key, as: Value.self)
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
        var hasRoot = false
        let rootInputSuffix = ".BodyInput<SwiftUI._ViewModifier_Content<SwiftUI.RootModifier>>"
        while let p = ptr {
            let key = _typeName(p.keyType, qualified: true)
            var isMatch = key.hasSuffix(rootInputSuffix)
            if isMatch {
                hasRoot = true
            }
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
                if let next = p.after {
                    // Reached the UIViewRepresentable
                    if _typeName(next.keyType, qualified: true).hasSuffix(branchKey) {
                        ptr = next
                    }
                }
                #endif
                break
            }
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
            if !hasRoot, let after = p.after {
                let key = _typeName(after.keyType, qualified: true)
                let isMatch = key.hasSuffix(rootInputSuffix) || key.hasSuffix(".ViewListOptionsInput") || key.hasSuffix(".AccessibilityRelationshipScope")
                if isMatch {
                    break
                }
            }
            last = p
        }

        ptr = elements
        let offset = tail.length - ((last?.length ?? 0) + 1)
        while offset > 0, let p = ptr {
            if let skip = p.skip, last?.length ?? 0 < skip.length, skip.length < tail.length {
                p.skip = last
                p.skipCount = p.length - (last?.length ?? 0)
            }
            p.length -= offset
            if p.skip == nil {
                p.skipCount = p.length
            }
            ptr = p.after
        }

        if let last {
            _ = last.object.retain() // Prevent dealloc
            tail.after = last
            tail.skip = last.skip
            tail.skipCount = last.skipCount + 1
        }
    }
}
