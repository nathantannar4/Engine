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
@propertyWrapper
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct UpdatePhase: DynamicProperty {

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

    @inlinable
    public init() {
        self.storage = StateObject(wrappedValue: Storage(value: Value()))
    }

    public mutating func update() {
        storage.wrappedValue.value.update()
    }

    public var wrappedValue: Value {
        storage.wrappedValue.value
    }

    @frozen
    public struct Value: Hashable, Sendable {
        @usableFromInline
        var phase: UInt32

        @inlinable
        public init() {
            self.phase = 0
        }

        mutating func update() {
            phase = phase &+ 1
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
                    Text("Increment")
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

                Text(value.description)
            }
        }
    }
}
