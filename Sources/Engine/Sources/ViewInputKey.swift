//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A static input key for a view
public protocol ViewInputKey: AnyViewInputKey {
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

/// A ``ViewInputsModifier`` that modifies the input ``ViewInput/Key`` value to ``ViewInput/value``
@frozen
public struct ViewInputModifier<Input: ViewInput>: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        UnaryViewAdaptor { // workaround crashes
            content.modifier(Modifier())
        }
    }

    private struct Modifier: ViewInputsModifier {
        static func makeInputs(inputs: inout ViewInputs) {
            inputs[Input.Key.self] = Input.value
        }
    }
}

/// Do not use directly, use ``ViewInputKey``
public protocol AnyViewInputKey {
    static var value: Any.Type { get }
}

extension ViewInputKey {
    public static var value: any Any.Type { Value.self }
}
