//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding: @retroactive ExpressibleByNilLiteral where Value: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = .constant(nil)
    }
}

extension Binding {

    /// Transforms the value to `true` when `nil`
    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNone]
    }

    /// Transforms the value to `true` when `.some`
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNotNone]
    }
}

extension Binding where Value == Optional<String> {

    /// Transforms a `nil` `String` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }
}

extension Binding where Value == Optional<Int> {

    /// Transforms a `nil` `Int` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }
}

extension Binding where Value == Bool {

    @inlinable
    public static prefix func !(_ value: Binding<Bool>) -> Binding<Bool> {
        value[keyPath: \.inverted]
    }
}

extension Bool {

    @usableFromInline
    var inverted: Bool {
        get { !self }
        set { self = !newValue }
    }
}

extension Binding where Value == Optional<Bool> {

    /// Transforms the value to `true` when `true`
    @inlinable
    public func isTrue() -> Binding<Bool> {
        self[keyPath: \.isTrue]
    }

    /// Transforms the value to `true` when `false`
    @inlinable
    public func isFalse() -> Binding<Bool> {
        self[keyPath: \.isFalse]
    }
}

extension Binding where Value == Optional<URL> {

    /// Transforms a `URL` to a `String`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }
}

// MARK: - Previews

struct Binding_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            OptionalBindingPreview(value: nil)
            OptionalBindingPreview(value: .constant(nil))

            Divider()

            InvertedBoolPreview()

            Divider()

            IsNilPreview()

            Divider()

            IsNotNilPreview()
        }
    }

    struct OptionalBindingPreview: View {
        @Binding var value: Int?

        var body: some View {
            Text(value?.description ?? "nil")
        }
    }

    struct InvertedBoolPreview: View {
        @State var isOn = true

        var body: some View {
            VStack {
                Toggle(isOn: $isOn) { }

                Toggle(isOn: !$isOn) { }
            }
            .labelsHidden()
        }
    }

    struct IsNilPreview: View {
        @State var value: String?
        @State var update = 0

        var body: some View {
            VStack {
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    ToggleView(isNil: $value.isNil())
                }

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

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    ToggleView(isNotNil: $value.isNotNil())
                }

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

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
