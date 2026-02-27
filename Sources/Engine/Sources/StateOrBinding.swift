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
        self.storage = .state(State(initialValue: value))
    }

    @inlinable
    public init(_ binding: Binding<Value>) {
        self.storage = .binding(binding)
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
    struct Preview: View {
        @State var value: Int = 0

        var body: some View {
            VStack(alignment: .leading) {
                Text("State:")

                ChildView(value: .init(0))

                Text("Binding: \(value)")

                ChildView(value: .init($value))
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
    }

    static var previews: some View {
        Preview()
    }
}
