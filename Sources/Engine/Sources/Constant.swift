//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A property wrapper that is always considered equal, regardless of its wrapped value
///
/// When SwiftUI compares a view's stored properties to determine if its body needs
/// to be updated, a change to a ``Constant`` property alone does not cause an update.
///
/// > Tip: Use ``Constant`` to improve performance
/// on views that store closures that don't need updates, such as
/// closures that don't capture any variables or only capture reference types.
///
@propertyWrapper
@frozen
public struct Constant<Value>: Equatable {

    /// The wrapped value.
    public let wrappedValue: Value

    /// Creates a constant from its wrapped value.
    @inlinable
    public init(
        wrappedValue: Value
    ) {
        self.wrappedValue = wrappedValue
    }

    /// Returns `true`, constants are always equal.
    public static func == (lhs: Constant<Value>, rhs: Constant<Value>) -> Bool {
        return true
    }
}

extension Constant: Sendable where Value: Sendable { }

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct Constant_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var value = 0

        var body: some View {
            VStack {
                Text(value.description)

                Button {
                    value += 1
                } label: {
                    Text("Increment")
                }

                ChildView {
                    value += 1
                }

                ChildConstantView {
                    value += 1
                }

                // Note that this captures a copy, and because its constant the capure won't update
                ChildConstantView { [curr = value] in
                    value = curr + 1
                }
            }
        }

        struct ChildView: View {
            var action: () -> Void

            var body: some View {
                Button {
                    action()
                } label: {
                    Text("ChildView Increment")
                }
                .withViewUpdateDebugView()
            }
        }

        struct ChildConstantView: View {
            @Constant
            var action: () -> Void

            var body: some View {
                Button {
                    action()
                } label: {
                    Text("ChildView Increment")
                }
                .withViewUpdateDebugView()
            }
        }
    }
}
