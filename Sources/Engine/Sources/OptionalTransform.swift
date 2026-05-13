//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding {

    /// A ``BindingTransform`` that transforms the value to `true` when `nil`
    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNone]
    }

    /// A ``BindingTransform`` that transforms the value to `true` when `.some`
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNotNone]
    }
}

extension Binding where Value == Optional<String> {

    /// A ``BindingTransform`` that transforms a `nil` `String` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct OptionalTransform_Previews: PreviewProvider {
    static var previews: some View {
        IsNilPreview()
        IsNotNilPreview()
    }

    struct IsNilPreview: View {
        @State var value: String?
        @State var update = 0

        var body: some View {
            VStack {
                ToggleView(isNil: $value.isNil())

                if let value {
                    Text(value)
                }

                Button {
                    value = "Hello, World"
                } label: {
                    Text("Add Text")
                }

                Button {
                    update += 1
                } label: {
                    Text("Render Update \(update)")
                }
            }
        }

        struct ToggleView: View {
            @Binding var isNil: Bool
            var body: some View {
                Self._printChanges()
                return Toggle(isOn: $isNil) { EmptyView() }
                    .labelsHidden()
            }
        }
    }

    struct IsNotNilPreview: View {
        @State var value: String?
        @State var update = 0

        var body: some View {
            VStack {
                ToggleView(isNotNil: $value.isNotNil())

                if let value {
                    Text(value)
                }

                Button {
                    value = "Hello, World"
                } label: {
                    Text("Add Text")
                }

                Button {
                    update += 1
                } label: {
                    Text("Render Update \(update)")
                }
            }
        }

        struct ToggleView: View {
            @Binding var isNotNil: Bool
            var body: some View {
                Self._printChanges()
                return Toggle(isOn: $isNotNil) { EmptyView() }
                    .labelsHidden()
            }
        }
    }
}
