//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that instantiates an optional observable object
/// and invalidates a view whenever the observable object changes.
@MainActor @preconcurrency
@propertyWrapper
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct OptionalStateObject<
    ObjectType: ObservableObject
>: @preconcurrency DynamicProperty {

    @MainActor @preconcurrency
    @usableFromInline
    class Storage: ObservableObject, DeallocationObserver {
        var value: ObjectType? {
            willSet {
                if newValue !== value, let value {
                    DeallocationTracker.shared(for: value).removeObserver(self)
                }
            }
            didSet {
                if oldValue !== value {
                    if let value {
                        bind(to: value)
                    }
                    objectWillChange.send()
                }
            }
        }

        private var cancellable: AnyCancellable?

        @usableFromInline
        init(value: @autoclosure @escaping () -> ObjectType?) {
            let value = value()
            self.value = value
            if let value {
                bind(to: value)
            }
        }

        private func bind(to value: ObjectType) {
            cancellable = value.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
            DeallocationTracker.shared(for: value).addObserver(self)
        }

        nonisolated func didDeinit() {
            if Thread.isMainThread {
                objectWillChange.send()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.objectWillChange.send()
                }
            }
        }
    }

    @usableFromInline
    var storage: StateObject<Storage>

    @inlinable
    public init(wrappedValue: @autoclosure @escaping () -> ObjectType?) {
        storage = StateObject<Storage>(wrappedValue: Storage(value: wrappedValue()))
    }

    public var wrappedValue: ObjectType? {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    public var projectedValue: OptionalObservedObject<ObjectType>.Binding {
        OptionalObservedObject<ObjectType>(wrappedValue: wrappedValue).projectedValue
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var _propertyBehaviors: UInt32 {
        StateObject<Storage>._propertyBehaviors
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct OptionalStateObject_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        class ViewModel: ObservableObject {
            @Published var value = 0

            deinit {
                print("deinit ViewModel")
            }
        }

        @OptionalStateObject var viewModel = ViewModel()
        @State var flag = false

        var body: some View {
            VStack {
                OptionalBindingValueView(value: $viewModel.value)

                OptionalValueView(value: $viewModel.value)

                OptionalView(viewModel: viewModel)

                Button {
                    viewModel = viewModel == nil ? ViewModel() : nil
                } label: {
                    Text("Toggle ViewModel")
                }
            }
        }

        struct OptionalView: View {
            @OptionalObservedObject var viewModel: ViewModel?

            var body: some View {
                Button {
                    viewModel?.value += 1
                } label: {
                    Text("Increment \(viewModel?.value ?? -1)")
                }
                .disabled(viewModel == nil)
            }
        }

        struct OptionalBindingValueView: View {
            var value: Binding<Int>?

            var body: some View {
                Text(value?.wrappedValue.description ?? "nil")
            }
        }

        struct OptionalValueView: View {
            @Binding var value: Int?

            var body: some View {
                Text(value?.description ?? "nil")
            }
        }
    }
}
