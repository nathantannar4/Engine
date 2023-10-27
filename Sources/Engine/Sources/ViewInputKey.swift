//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A static input key for a view
public protocol ViewInputKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

/// A static input for a view
public protocol ViewInput {
    associatedtype Key: ViewInputKey
    static var value: Key.Value { get }
}

/// A ``ViewInput`` that's ``ViewInput/Value`` is a `Bool` that defaults to `true`.
public protocol ViewInputFlag: ViewInput, ViewInputKey, ViewInputsCondition where Key == Self, Value == Bool { }

extension ViewInputFlag {
    public static var value: Bool { true }
    public static var defaultValue: Bool { false }
}

/// A static condition that is conditional on a view's inputs.
public protocol ViewInputsCondition {
    static func evaluate(_ inputs: ViewInputs) -> Bool
}

extension ViewInputsCondition where Self: ViewInputFlag {
    /// Evaluates to `true` when the input value is `true`
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        inputs[Self.Key.self] == true
    }
}

extension View {
    /// Modifies the view inputs to set the ``ViewInput/value``
    @inlinable
    public func input<Input: ViewInput>(
        _: Input.Type
    ) -> some View {
        modifier(ViewInputModifier<Input>())
    }
}

/// A `ViewModifier` that only modifies the static inputs
public protocol ViewInputsModifier: _GraphInputsModifier, ViewModifier where Body == Never {
    static func makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs)
}

extension ViewInputsModifier {
    public static func _makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        makeInputs(modifier: modifier, inputs: &inputs)
    }
}

/// A ``ViewInputsModifier`` that modifies the input ``ViewInput/Key`` value to ``ViewInput/value``
@frozen
public struct ViewInputModifier<Input: ViewInput>: ViewInputsModifier {

    @inlinable
    public init() { }

    public static func makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        inputs[Input.Key.self] = Input.value
    }
}
