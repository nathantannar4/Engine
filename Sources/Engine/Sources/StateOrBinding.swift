//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A property wrapper that can read and write a value from
/// a wrapped `State` or `Binding`
@propertyWrapper
@frozen
public struct StateOrBinding<Value>: DynamicProperty {

    @usableFromInline
    enum Storage: DynamicProperty {
        case state(State<Value>)
        case binding(Binding<Value>)
    }

    @usableFromInline
    var storage: Storage

    @inlinable
    public init(_ value: Value) {
        self.storage = .state(State(wrappedValue: value))
    }

    @inlinable
    public init(_ binding: Binding<Value>) {
        self.storage = .binding(binding)
    }

    @inlinable
    public init<V>(_ binding: Binding<V?>?) where Value == V? {
        self.storage = binding.map({ .binding($0) }) ?? .state(State(wrappedValue: nil))
    }

    public var wrappedValue: Value {
        get {
            switch storage {
            case .state(let state):
                return state.wrappedValue
            case .binding(let binding):
                return binding.wrappedValue
            }
        }
        nonmutating set {
            switch storage {
            case .state(let state):
                state.wrappedValue = newValue
            case .binding(let binding):
                binding.wrappedValue = newValue
            }
        }
    }

    public var projectedValue: Binding<Value> {
        switch storage {
        case .state(let state):
            return state.projectedValue
        case .binding(let binding):
            return binding
        }
    }
}

extension StateOrBinding: Sendable where Value: Sendable { }
extension StateOrBinding.Storage: Sendable where Value: Sendable { }

// MARK: - Previews

struct StateOrBinding_Previews: PreviewProvider {

    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value: Int = 0
        @State var optionalValue: Int?

        var body: some View {
            VStack(alignment: .leading) {
                Text("State:")

                ChildView(value: .init(0))

                Text("Binding: \(value)")

                ChildView(value: .init($value))

                OptionalBindingChildView()

                OptionalBindingChildView(value: $optionalValue)
            }
        }

        struct ChildView: View {
            @StateOrBinding var value: Int

            var body: some View {
                Button(value.description) {
                    value += 1
                }
            }
        }

        struct OptionalBindingChildView: View {
            var value: Binding<Int?>?

            var body: some View {
                OptionalChildView(value: .init(value))
            }
        }

        struct OptionalChildView: View {
            @StateOrBinding var value: Int?

            var body: some View {
                Button(value?.description ?? "nil") {
                    value = (value ?? -1) + 1
                }
            }
        }
    }
}
