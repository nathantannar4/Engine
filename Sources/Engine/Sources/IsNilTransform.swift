//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``BindingTransform`` that transforms the value to a `Bool`
///
/// The transform will return `true` when the value is `nil`. If the projected
/// value is set to `true`, the value will be set to `nil`.
@frozen
public struct IsNilTransform<Input>: BindingTransform {

    @inlinable
    public init() { }

    public func get(_ value: Input?) -> Bool {
        value == nil
    }

    public func set(_ newValue: Output, oldValue: @autoclosure () -> Input?) throws -> Input? {
        if newValue {
            return nil
        }
        return oldValue()
    }
}

extension Binding {

    /// A ``BindingTransform`` that transforms the value to `true` when `nil`
    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        projecting(IsNilTransform())
    }
}

// MARK: - Previews

struct IsNilTransform_Previews: PreviewProvider {
    struct Preview: View {
        @State var value: String?

        var body: some View {
            VStack {
                Toggle(isOn: $value.isNil()) {
                    if let value = value {
                        Text(value)
                    }
                }

                Button {
                    value = "Hello, World"
                } label: {
                    Text("Add Text")
                }
            }
        }
    }
    static var previews: some View {
        Preview()
    }
}
