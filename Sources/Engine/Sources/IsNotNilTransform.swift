//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``BindingTransform`` that transforms the value to a `Bool`
///
/// The transform will return `true` when the value is not `nil`. If the projected
/// value is set to `false`, the value will be set to `nil`.
@frozen
public struct IsNotNilTransform<Input>: BindingTransform {

    @inlinable
    public init() { }

    public func get(_ value: Input?) -> Bool {
        value != nil
    }

    public func set(_ newValue: Output, oldValue: @autoclosure () -> Input?) throws -> Input? {
        if !newValue {
            return nil
        }
        return oldValue()
    }
}

extension Binding {

    /// A ``BindingTransform`` that transforms the value to `true` when not `nil`
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        projecting(IsNotNilTransform())
    }
}

// MARK: - Previews

struct IsNotNilTransform_Previews: PreviewProvider {
    struct Preview: View {
        @State var value: String?

        var body: some View {
            VStack {
                Toggle(isOn: $value.isNotNil()) {
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
