//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that subscribes to an optional observable
/// object and invalidates a view whenever the observable object changes.
@MainActor @preconcurrency
@propertyWrapper
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct OptionalObservedObject<
    ObjectType: ObservableObject
>: @preconcurrency DynamicProperty {

    @MainActor @preconcurrency
    @usableFromInline
    class Storage: ObservableObject, DeallocationObserver {
        weak var value: ObjectType?

        private var cancellable: AnyCancellable?

        @usableFromInline
        init(value: ObjectType?) {
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
    var storage: ObservedObject<Storage>

    @inlinable
    public init(wrappedValue: ObjectType?) {
        storage = ObservedObject<Storage>(wrappedValue: Storage(value: wrappedValue))
    }

    public var wrappedValue: ObjectType? {
        get { storage.wrappedValue.value }
    }

    public var projectedValue: Binding {
        Binding(root: storage.projectedValue.value)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var _propertyBehaviors: UInt32 {
        ObservedObject<Storage>._propertyBehaviors
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
struct OptionalObservedObject_Previews: PreviewProvider {
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

            @MainActor
            static var shared: ViewModel? = ViewModel()
        }

        @StateObject var viewModel = ViewModel()
        @State var flag = false
        @State var update = 0

        var body: some View {
            VStack {
                Text(viewModel.value.description)

                OptionalView(viewModel: nil)

                OptionalView(viewModel: viewModel)

                HStack {
                    OptionalView(viewModel: flag ? ViewModel.shared : viewModel)

                    Button {
                        flag.toggle()
                    } label: {
                        Text("Toggle")
                    }
                }

                HStack {
                    OptionalView(viewModel: ViewModel.shared)

                    Button {
                        if ViewModel.shared == nil {
                            ViewModel.shared = ViewModel()
                            // Trigger an update for OptionalView
                            update += 1
                        } else {
                            // OptionalObservedObject should update OptionalView
                            ViewModel.shared = nil
                        }
                    } label: {
                        Text("Toggle Shared")
                    }
                    .onChange(of: update) { _ in }
                }
            }
        }

        struct OptionalView: View {
            @OptionalObservedObject var viewModel: ViewModel?

            var body: some View {
                HStack {
                    OptionalBindingValueView(value: $viewModel.value)

                    OptionalValueView(value: $viewModel.value)

                    Button {
                        viewModel?.value += 1
                    } label: {
                        Text("Increment \(viewModel?.value ?? -1)")
                    }
                    .disabled(viewModel == nil)
                }
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
