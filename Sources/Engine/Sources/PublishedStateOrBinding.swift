//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A property wrapper that can read and write a value from
/// a wrapped `PublishedState` or `Binding`
@MainActor @preconcurrency
@propertyWrapper
@frozen
public struct PublishedStateOrBinding<Value>: DynamicProperty {

    @usableFromInline
    enum Storage: DynamicProperty {
        case published(PublishedState<Value>.Binding)
        case binding(Binding<Value>)
    }

    @usableFromInline
    var storage: Storage

    @inlinable
    public init(_ binding: PublishedState<Value>.Binding) {
        self.storage = .published(binding)
    }

    @inlinable
    public init(_ binding: Binding<Value>) {
        self.storage = .binding(binding)
    }

    public var wrappedValue: Value {
        get {
            switch storage {
            case .published(let state):
                return state.wrappedValue
            case .binding(let binding):
                return binding.wrappedValue
            }
        }
        nonmutating set {
            switch storage {
            case .published(let state):
                state.wrappedValue = newValue
            case .binding(let binding):
                binding.wrappedValue = newValue
            }
        }
    }

    public var projectedValue: Binding<Value> {
        switch storage {
        case .published(let state):
            return state.projectedValue
        case .binding(let binding):
            return binding
        }
    }

    public var publisher: PublishedState<Value>.Publisher? {
        switch storage {
        case .published(let state):
            return state.publisher
        case .binding:
            return nil
        }
    }
}

// MARK: - Previews

struct PublishedStateOrBinding_Previews: PreviewProvider {
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
