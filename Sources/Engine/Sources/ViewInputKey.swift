//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A static input key for a view.
public protocol ViewInputKey {
    /// The type of value for the key.
    associatedtype Value
    /// The default value for the key, when the input has not been set.
    static var defaultValue: Value { get }
}

/// A static input for a view.
public protocol ViewInput {
    /// The key of the input.
    associatedtype Key: ViewInputKey
    /// The value of the input, set with `input(_:)`.
    static var value: Key.Value { get }
}

/// A ``ViewInput`` and ``ViewInputKey`` whose value is a `Bool`.
///
/// By default, the ``ViewInput/value`` of a flag is `true` and its ``ViewInputKey/defaultValue`` is the opposite.
public protocol ViewInputFlag: ViewInput, ViewInputKey, ViewInputsCondition where Key == Self, Value == Bool { }

extension ViewInputFlag {
    public static var value: Bool { true }
    public static var defaultValue: Bool { !value }
}

extension View {

    /// Modifies the view inputs to set the input's ``ViewInput/Key`` to its ``ViewInput/value``.
    @inlinable
    public func input<Input: ViewInput>(
        _: Input.Type
    ) -> some View {
        modifier(ViewInputModifier<Input>())
    }

    /// Modifies the view inputs to reset the flag to its ``ViewInputKey/defaultValue``.
    @inlinable
    public func defaultInput<Input: ViewInputFlag>(
        _: Input.Type
    ) -> some View {
        modifier(ViewInputFlagDefaultModifier<Input>())
    }
}

/// A modifier that sets the input's ``ViewInput/Key`` to its ``ViewInput/value``.
@frozen
public struct ViewInputModifier<Input: ViewInput>: ViewModifier {

    /// Creates the modifier.
    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .modifier(Modifier())
            .modifier(UnaryViewModifier())
    }

    private struct Modifier: ViewInputsModifier {
        static func makeInputs(inputs: inout ViewInputs) {
            inputs[Input.Key.self] = Input.value
        }
    }
}

/// A modifier that resets the flag to its ``ViewInputKey/defaultValue``.
@frozen
public struct ViewInputFlagDefaultModifier<Input: ViewInputFlag>: ViewModifier {

    /// Creates the modifier.
    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .modifier(Modifier())
            .modifier(UnaryViewModifier())
    }

    private struct Modifier: ViewInputsModifier {
        static func makeInputs(inputs: inout ViewInputs) {
            inputs[Input.Key.self] = Input.defaultValue
        }
    }
}

// MARK: - Previews

struct ViewInput_Previews: PreviewProvider {

    struct PreviewFlag: ViewInputFlag { }

    static var previews: some View {
        VStack {
            ViewInputConditionalContent(PreviewFlag.self) {
                Text("TRUE")
            } otherwise: {
                Text("FALSE")
            }
            .input(PreviewFlag.self)

            ViewInputConditionalContent(PreviewFlag.self) {
                Text("TRUE")
            } otherwise: {
                Text("FALSE")
            }

            ViewInputConditionalContent(PreviewFlag.self) {
                Text("TRUE")
            } otherwise: {
                Text("FALSE")
            }
            .defaultInput(PreviewFlag.self)
            .input(PreviewFlag.self)
        }
    }
}
