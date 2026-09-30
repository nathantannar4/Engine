//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that can read and write a value but does
/// not invalidate a view when changed.
///
/// > Tip: Use ``PublishedState`` to improve performance
/// when your view does not need to be invalidated for every change.
/// Instead, use the binding or publisher.
///
@MainActor @preconcurrency
@propertyWrapper
@frozen
public struct PublishedState<Value>: DynamicProperty {

    public typealias Publisher = AnyPublisher<Value, Never>

    @usableFromInline
    final class PublisherStorage: ObservableObject {
        @Published var value: Value
        private var cancellables = Set<AnyCancellable>()
        private var isSynchronizing = false
        // Children are cached weakly so that repeated `$state.member` access returns
        // the same storage, which keeps a `Binding` equal between view updates
        private var children = [AnyKeyPath: WeakChild]()

        private struct WeakChild {
            weak var storage: AnyObject?
        }

        @usableFromInline
        init(value: Value) {
            self._value = Published(wrappedValue: value)
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        subscript<Subject>(
            dynamicMember keyPath: WritableKeyPath<Value, Subject>
        ) -> PublishedState<Subject>.PublisherStorage where Value: Equatable, Subject: Equatable {
            if let storage = children[keyPath]?.storage as? PublishedState<Subject>.PublisherStorage {
                return storage
            }
            let storage = PublishedState<Subject>.PublisherStorage(value: value[keyPath: keyPath])
            children[keyPath] = WeakChild(storage: storage)
            // Both subscriptions are owned by the child storage, so that they are
            // cancelled when the child is released rather than accumulating in the parent
            // `@Published` emits during `willSet`, so a flag is used rather than comparing
            // values to prevent a change from being echoed back to where it came from
            $value
                .removeDuplicates()
                .map { $0[keyPath: keyPath] }
                .sink { [weak storage] newValue in
                    guard let storage, !storage.isSynchronizing else { return }
                    storage.isSynchronizing = true
                    defer { storage.isSynchronizing = false }
                    storage.value = newValue
                }
                .store(in: &storage.cancellables)

            storage.$value
                .dropFirst()
                .removeDuplicates()
                .sink { [weak self, weak storage] newValue in
                    guard let self, let storage, !storage.isSynchronizing else { return }
                    storage.isSynchronizing = true
                    defer { storage.isSynchronizing = false }
                    self.value[keyPath: keyPath] = newValue
                }
                .store(in: &storage.cancellables)
            return storage
        }
    }

    @usableFromInline
    var storage: State<PublisherStorage>

    @inlinable
    public init(wrappedValue: Value) {
        storage = State(wrappedValue: PublisherStorage(value: wrappedValue))
    }

    public var wrappedValue: Value {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    public var projectedValue: Binding {
        Binding(storage.wrappedValue)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public nonisolated static var _propertyBehaviors: UInt32 {
        State<PublisherStorage>._propertyBehaviors
    }

    @MainActor @preconcurrency
    @frozen
    @dynamicMemberLookup
    @propertyWrapper
    public struct Binding: DynamicProperty {

        @MainActor @preconcurrency
        @usableFromInline
        enum Storage: DynamicProperty {
            case publisher(ObservedObject<PublisherStorage>)
            case constant(Value)

            var value: Value {
                get {
                    switch self {
                    case .publisher(let storage):
                        return storage.wrappedValue.value
                    case .constant(let value):
                        return value
                    }
                }
                nonmutating set {
                    switch self {
                    case .publisher(let storage):
                        return storage.wrappedValue.value = newValue
                    case .constant:
                        break
                    }
                }
            }

            var projectedValue: SwiftUI.Binding<Value> {
                switch self {
                case .publisher(let storage):
                    return storage.projectedValue.value
                case .constant(let value):
                    return .constant(value)
                }
            }

            var publisher: Publisher {
                switch self {
                case .publisher(let storage):
                    return storage.wrappedValue.$value.eraseToAnyPublisher()
                case .constant(let value):
                    return Just(value).eraseToAnyPublisher()
                }
            }
        }

        @usableFromInline
        var storage: Storage

        init(_ storage: PublisherStorage) {
            self.storage = .publisher(ObservedObject(wrappedValue: storage))
        }

        init(_ constant: Value) {
            self.storage = .constant(constant)
        }

        public static func constant(_ value: Value) -> Binding {
            Binding(value)
        }

        public var wrappedValue: Value {
            get { storage.value }
            nonmutating set { storage.value = newValue }
        }

        public var projectedValue: SwiftUI.Binding<Value> {
            storage.projectedValue
        }

        public var publisher: Publisher {
            storage.publisher
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public subscript<Subject>(
            dynamicMember keyPath: WritableKeyPath<Value, Subject>
        ) -> PublishedState<Subject>.Binding where Value: Equatable, Subject: Equatable {
            switch storage {
            case .publisher(let storage):
                return PublishedState<Subject>.Binding(storage.wrappedValue[dynamicMember: keyPath])
            case .constant(let value):
                return .constant(value[keyPath: keyPath])
            }
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public nonisolated static var _propertyBehaviors: UInt32 {
            ObservedObject<PublisherStorage>._propertyBehaviors
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct PublishedState_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        struct Item: Equatable {
            var value: Int
        }
        @PublishedState var value = 0
        @PublishedState var item = Item(value: 20)
        @PublishedState var values: [Int: Int] = [0 : 0]

        var body: some View {
            VStack {
                Text(value.description)

                PublishedBindingChildView(value: .constant(-1))

                PublishedBindingChildView(value: $item.value)

                PublishedBindingChildView(value: $item.value)

                PublishedBindingChildView(value: $value)

                BindingChildView(value: $value.projectedValue)

                PublisherChildView(publisher: $value.publisher)

                PublishedStateReader($value) { $value in
                    Text(value.description)
                }

                PublishedOptionalBindingChildView(value: $values[keyPath: \.[0]])

                Button {
                    value += 1
                    item.value += 1
                    values[0, default: 0] += 1
                } label: {
                    Text("Increment")
                }
            }
        }

        struct PublishedBindingChildView: View {
            @PublishedState.Binding var value: Int

            var body: some View {
                Button {
                    value += 1
                } label: {
                    Text(value.description)
                }
            }
        }

        struct PublishedOptionalBindingChildView: View {
            @PublishedState.Binding var value: Int?

            var body: some View {
                Button {
                    value = value.map { $0 + 1 } ?? 0
                } label: {
                    Text(value?.description ?? "nil")
                }
            }
        }

        struct BindingChildView: View {
            @Binding var value: Int

            var body: some View {
                Button {
                    value += 1
                } label: {
                    Text(value.description)
                }
            }
        }

        struct PublisherChildView: View {
            var publisher: PublishedState<Int>.Publisher
            @State var value: Int?

            init(
                publisher: PublishedState<Int>.Publisher
            ) {
                self.publisher = publisher
            }

            var body: some View {
                Text(value?.description ?? "nil")
                    .onReceive(publisher) { newValue in
                        value = newValue
                    }
            }
        }
    }
}
