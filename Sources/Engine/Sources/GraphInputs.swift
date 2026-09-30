//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A `ViewModifier` that only modifies the static inputs
public protocol GraphInputsModifier: _GraphInputsModifier, ViewModifier where Body == Never {
    nonisolated static func makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs)
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

extension _GraphInputs {

    @usableFromInline
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

    /// Accesses the value of the custom input for the given ``ViewInputKey``.
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    /// Accesses the value of the custom input for the given ``ViewInputKey``,
    /// or `defaultValue` if the input has not been set.
    public subscript<Input: ViewInputKey>(
        _ : Input.Type,
        default defaultValue: @autoclosure () -> Input.Value?
    ) -> Input.Value? {
        get { customInputs[Input.self, default: defaultValue()] }
        set { customInputs[Input.self, default: defaultValue()] = newValue }
    }

    /// Accesses the value of the custom input whose key type name matches `key`.
    ///
    /// > Warning: Setting a value only has an effect if an input with a matching key already exists
    public subscript<Value>(
        key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
        set { customInputs[key, as: Value.self] = newValue }
    }
}
