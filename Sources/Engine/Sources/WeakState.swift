//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

@propertyWrapper
@MainActor @preconcurrency
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct WeakState<
    ObjectType: AnyObject
>: @preconcurrency DynamicProperty {

    @usableFromInline
    @MainActor @preconcurrency
    class Storage: ObservableObject, DeallocationObserver {
        weak var value: ObjectType? {
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
        @usableFromInline
        init(value: ObjectType?) {
            self.value = value
            if let value {
                bind(to: value)
            }
        }

        private func bind(to value: ObjectType) {
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
    init(wrappedValue thunk: @autoclosure @escaping () -> ObjectType?) {
        storage = StateObject<Storage>(wrappedValue: { Storage(value: thunk()) }())
    }

    var wrappedValue: ObjectType? {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    var projectedValue: Binding {
        Binding(root: storage.projectedValue.value)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var _propertyBehaviors: UInt32 {
        StateObject<Storage>._propertyBehaviors
    }

    @MainActor @preconcurrency
    @frozen
    @dynamicMemberLookup
    public struct Binding {
        let root: SwiftUI.Binding<ObjectType?>

        public subscript<Subject>(
            dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>
        ) -> SwiftUI.Binding<Subject?> {
            guard let binding = SwiftUI.Binding<ObjectType>(root) else { return .constant(nil) }
            return SwiftUI.Binding(binding[dynamicMember: keyPath])
        }

        public subscript<Subject>(
            dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>
        ) -> SwiftUI.Binding<Subject>? {
            SwiftUI.Binding<ObjectType>(root)?[dynamicMember: keyPath]
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct WeakState_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        class ViewModel {
            var value = 0 {
                didSet {
                    print(value)
                }
            }

            deinit {
                print("deinit ViewModel")
            }

            @MainActor
            static var shared: ViewModel? = ViewModel()
        }

        @WeakState var viewModel = ViewModel.shared

        var body: some View {
            VStack {
                OptionalBindingValueView(value: $viewModel.value)

                OptionalValueView(value: $viewModel.value)

                Text(viewModel == nil ? "nil" : "non-nil")

                Button {
                    if ViewModel.shared == nil {
                        ViewModel.shared = ViewModel()
                        viewModel = ViewModel.shared
                    } else {
                        ViewModel.shared = nil
                    }
                } label: {
                    Text("Toggle")
                }
            }
        }

        struct OptionalBindingValueView: View {
            var value: Binding<Int>?

            var body: some View {
                Button {
                    value?.wrappedValue = (value?.wrappedValue ?? 0) + 1
                } label: {
                    Text(value?.wrappedValue.description ?? "nil")
                }
                .disabled(value == nil)
            }
        }

        struct OptionalValueView: View {
            @Binding var value: Int?

            var body: some View {
                Button {
                    value? = (value ?? 0) + 1
                } label: {
                    Text(value?.description ?? "nil")
                }
            }
        }
    }
}

