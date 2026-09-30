//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that automatically updates its value
/// when the `View` it is attached to updates.
///
/// > Tip: Useful for when you need to observe when a view updates
///
@MainActor @preconcurrency
@propertyWrapper
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct UpdatePhase: @preconcurrency DynamicProperty {

    @usableFromInline
    final class Storage: ObservableObject {
        var value: Value

        @usableFromInline
        init(value: Value) {
            self.value = value
        }
    }

    @usableFromInline
    var storage: StateObject<Storage>

    /// Creates an update phase with zero updates.
    @inlinable
    public init() {
        self.storage = StateObject(wrappedValue: Storage(value: Value()))
    }

    /// Increments the update count of the phase. Called by SwiftUI each time the
    /// view updates, before it renders its body.
    @MainActor
    public func update() {
        storage.wrappedValue.value.update()
    }

    /// The current phase of the view.
    public var wrappedValue: Value {
        storage.wrappedValue.value
    }

    /// A value that identifies an update phase of a view.
    @frozen
    public struct Value: Hashable, Sendable {
        @usableFromInline
        var phase: UInt32

        /// Creates a phase with zero updates.
        @inlinable
        public init() {
            self.phase = 0
        }

        /// The number of updates, which wraps around on overflow.
        public var updates: UInt32 {
            phase
        }

        /// Increments the number of updates.
        public mutating func update() {
            phase &+= 1
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct UpdatePhase_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value = 0
        @UpdatePhase var phase

        var body: some View {
            VStack {
                Button {
                    value += 1
                } label: {
                    Text(verbatim: "Increment \(value)")
                }
                #if os(visionOS)
                .onChange(of: phase) { _, _ in
                    print("View Updated")
                }
                #else
                .onChange(of: phase) { _ in
                    print("View Updated")
                }
                #endif

                Text(phase.phase.description)
            }
        }
    }
}
