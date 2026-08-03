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
        }
    }
}
