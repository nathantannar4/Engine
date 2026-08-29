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

    @inlinable
    public func asOptional() -> Binding<Value?> where Value: Equatable {
        self[keyPath: \.optional]
    }

    /// Transforms a `nil` value to the `defaultValue` when nil
    @inlinable
    public func unwrap<Wrapped: Hashable>(
        defaultValue: Wrapped
    ) -> Binding<Wrapped> where Value == Optional<Wrapped> {
        self[keyPath: \.[defaultValue]]
    }

    /// Transforms a `nil` value to the `defaultValue` when nil
    @inlinable
    public subscript<Wrapped: Hashable>(
        default defaultValue: Wrapped
    ) -> Binding<Wrapped> where Value == Optional<Wrapped> {
        self[keyPath: \.[defaultValue]]
    }

    /// Unwraps a `Binding` with an optional wrapped value to an optional `Binding`
    @inlinable
    @MainActor @preconcurrency
    public func unwrap<Wrapped>() -> Binding<Wrapped>? where Optional<Wrapped> == Value {
        guard let value = self.wrappedValue else { return nil }
        return Binding<Wrapped>(
            get: { return value },
            set: { value, transaction in
                self.transaction(transaction).wrappedValue = value
            }
        )
    }
}

extension Binding where Value == Optional<String> {

    /// Transforms a `nil` `String` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }

    /// Transforms a `nil` `String` to the `defaultValue` when nil
    @inlinable
    public func value(defaultValue: String) -> Binding<String> {
        self[keyPath: \.[defaultValue]]
    }
}

extension Binding where Value == Optional<Int> {

    /// Transforms a `nil` `Int` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }

    /// Transforms a `Int` to a `String` using the `defaultValue` when nil
    @inlinable
    public func value(defaultValue: String) -> Binding<String> {
        self[keyPath: \.[defaultValue]]
    }
}

extension Binding where Value == Optional<Double> {

    /// Transforms a `nil` `Double` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }

    /// Transforms an `Double` to a `String` using the `defaultValue` when nil
    @inlinable
    public func value(defaultValue: String) -> Binding<String> {
        self[keyPath: \.[defaultValue]]
    }
}

extension Binding where Value == Optional<Float> {

    /// Transforms a `nil` `Float` to an empty string, and an empty `String` to `nil`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }

    /// Transforms an `Float` to a `String` using the `defaultValue` when nil
    @inlinable
    public func value(defaultValue: String) -> Binding<String> {
        self[keyPath: \.[defaultValue]]
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

extension Binding where Value == Bool {

    @inlinable
    public static prefix func !(_ value: Binding<Bool>) -> Binding<Bool> {
        value[keyPath: \.inverted]
    }

    @inlinable
    public func toggle() {
        wrappedValue.toggle()
    }
}

extension Bool {

    @usableFromInline
    var inverted: Bool {
        get { !self }
        set { self = !newValue }
    }
}

extension Binding where Value == Optional<URL> {

    /// Transforms a `URL` to a `String`
    @inlinable
    public func value() -> Binding<String> {
        self[keyPath: \.value]
    }

    /// Transforms a `URL` to a `String` using the `defaultValue` when nil
    @inlinable
    public func value(defaultValue: String) -> Binding<String> {
        self[keyPath: \.[defaultValue]]
    }
}

extension Binding {

    /// Transforms a `Set` to a `Bool`
    @inlinable
    public func contains<Element: Hashable>(
        _ id: Element
    ) -> Binding<Bool> where Value: SetAlgebra, Value.Element == Element {
        self[keyPath: \.[id]]
    }
}

extension SetAlgebra {

    @usableFromInline
    subscript(_ id: Element) -> Bool where Element: Hashable {
        get { contains(id) }
        set {
            if newValue {
                insert(id)
            } else {
                remove(id)
            }
        }
    }
}

extension Binding {

    /// Transforms a `RangeReplaceableCollection` to a `Bool`
    @inlinable
    public func contains(
        _ element: Value.Element
    ) -> Binding<Bool> where Value: RangeReplaceableCollection & Hashable, Value.Element: Hashable {
        self[keyPath: \.[element]]
    }
}

extension RangeReplaceableCollection {

    @usableFromInline
    subscript(_ element: Element) -> Bool where Element: Hashable {
        get { contains(element) }
        set {
            let index = firstIndex(of: element)
            if newValue, index == nil {
                append(element)
            } else if !newValue, let index {
                remove(at: index)
            }
        }
    }
}

extension Binding {

    /// Transforms a `RandomAccessCollection` to its `Index`
    @inlinable
    public func index<
        Collection: RandomAccessCollection & Hashable
    >(_ elements: Collection) -> Binding<Collection.Index?> where Collection.Element: Hashable, Value == Optional<Collection.Element> {
        self[keyPath: \.[elements]]
    }

    /// Transforms a `RandomAccessCollection` to its `Index`
    @inlinable
    public func index<
        Collection: RandomAccessCollection & Hashable
    >(_ elements: Collection) -> Binding<Collection.Index> where Collection.Element: Hashable, Value == Collection.Element {
        self[keyPath: \.[elements]]
    }
}

extension Hashable {

    @usableFromInline
    subscript<
        Collection: RandomAccessCollection & Hashable
    >(_ elements: Collection) -> Collection.Index? where Self == Optional<Collection.Element> {
        get {
            if let element = self {
                return elements.firstIndex(of: element)
            }
            return nil
        }
        set {
            if let newValue, elements.indices.contains(newValue) {
                self = elements[newValue]
            } else {
                self = .none
            }
        }
    }

    @usableFromInline
    subscript<
        Collection: RandomAccessCollection & Hashable
    >(_ elements: Collection) -> Collection.Index where Self == Collection.Element {
        get { elements.firstIndex(of: self)! }
        set {
            if elements.indices.contains(newValue) {
                self = elements[newValue]
            }
        }
    }
}

// MARK: - Previews

struct Binding_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            OptionalBindingPreview(value: nil)
            OptionalBindingPreview(value: .constant(nil))

            Divider()

            OptionalValuesPreview()

            Divider()

            InvertedBoolPreview()

            Divider()

            IsNilPreview()

            Divider()

            IsNotNilPreview()

            Divider()

            HashableSetPreview()

            EnumSetPreview()

            OptionSetPreview()

            CollectionPreview()

            SelectionPreview()
        }
    }

    struct OptionalBindingPreview: View {
        @Binding var value: Int?

        var body: some View {
            Text(value?.description ?? "nil")
        }
    }

    struct OptionalValuesPreview: View {
        @State var text: String?
        @State var number: Int?
        @State var url: URL?

        @State var defaultNumber = 0

        var body: some View {
            VStack {
                HStack {
                    Text(text?.description ?? "nil")
                    TextField("String", text: $text.value())
                    TextField("String", text: $text.value(defaultValue: ""))
                }

                HStack {
                    Text(number?.description ?? "nil")
                    TextField("Int", text: $number.value())
                    TextField("Int", text: $number.value(defaultValue: ""))
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        TextField("Int", value: $number, format: .number)
                    }
                }

                HStack {
                    Text(url?.absoluteString ?? "nil")
                    TextField("URL", text: $url.value())
                }
            }
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

    struct HashableSetPreview: View {
        struct ID: Hashable {
            var value: String
        }

        @State var selection = Set<ID>()

        var body: some View {
            VStack {
                Text(selection.description)

                Toggle(isOn: $selection.contains(ID(value: "preview"))) { EmptyView() }
                    .labelsHidden()
            }
        }
    }

    struct EnumSetPreview: View {
        enum Options: String {
            case one
            case two
        }

        @State var selection = Set<Options>()

        var body: some View {
            VStack {
                Text(selection.description)

                Toggle(isOn: $selection.contains(.one)) {
                    Text("Toggle One")
                }

                Button {
                    $selection.contains(.two).toggle()
                } label: {
                    Text("Toggle Two")
                }
            }
        }
    }

    struct OptionSetPreview: View {
        struct Selection: OptionSet, Hashable {
            var rawValue: Int

            static let enabled = Selection(rawValue: 1)
        }

        @State var selection = Selection()

        var body: some View {
            VStack {
                Text(selection.rawValue.description)

                Toggle(isOn: $selection.contains(.enabled)) { EmptyView() }
                    .labelsHidden()
            }
        }
    }

    struct CollectionPreview: View {
        @State var selection: [String] = []

        var body: some View {
            VStack {
                Text(selection.description)

                Toggle(isOn: $selection.contains("Hello, World")) { EmptyView() }
                    .labelsHidden()
            }
        }
    }

    struct SelectionPreview: View {
        struct PickerView<Selection: Hashable & Identifiable, Label: View>: View {
            @Binding var selection: Selection
            var options: [Selection]
            var label: (Selection) -> Label

            var body: some View {
                VStack {
                    HStack {
                        let index: Binding<Int> = $selection.index(options)
                        Button {
                            index.wrappedValue -= 1
                        } label: {
                            Text("Prev")
                        }

                        Text(index.wrappedValue.description)

                        Button {
                            index.wrappedValue += 1
                        } label: {
                            Text("Next")
                        }
                    }

                    HStack {
                        ForEach(options) { option in
                            let isSelected = option == selection
                            Button {
                                selection = option
                            } label: {
                                label(option)
                                    .border(isSelected ? Color.blue : Color.clear)
                            }
                        }
                    }
                }
            }
        }

        struct OptionalPickerView<Selection: Hashable & Identifiable, Label: View>: View {
            @Binding var selection: Selection?
            var options: [Selection]
            var label: (Selection) -> Label

            var body: some View {
                VStack {
                    HStack {
                        let index: Binding<Int?> = $selection.index(options)
                        Button {
                            index.wrappedValue = index.wrappedValue.map { $0 - 1 } ?? 0
                        } label: {
                            Text("Prev")
                        }

                        Text(index.wrappedValue?.description ?? "nil")

                        Button {
                            index.wrappedValue = index.wrappedValue.map { $0 + 1 } ?? options.count - 1
                        } label: {
                            Text("Next")
                        }
                    }

                    HStack {
                        ForEach(options) { option in
                            let isSelected = option == selection
                            Button {
                                selection = option
                            } label: {
                                label(option)
                                    .border(isSelected ? Color.blue : Color.clear)
                            }
                        }
                    }
                }
            }
        }

        enum Options: Hashable, Identifiable, CaseIterable {
            case one
            case two
            case three

            var id: Self {
                self
            }

            var label: String {
                switch self {
                case .one:
                    return "One"
                case .two:
                    return "Two"
                case .three:
                    return "Three"
                }
            }
        }
        @State var selection: Options = .one
        @State var optionalSelection: Options?

        var body: some View {
            HStack {
                PickerView(
                    selection: $selection,
                    options: Options.allCases
                ) { option in
                    Text(option.label)
                }

                OptionalPickerView(
                    selection: $optionalSelection,
                    options: Options.allCases
                ) { option in
                    Text(option.label)
                }
            }
        }
    }
}
