//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that writes a value to the environment, or leaves the
/// environment value unchanged when no value is provided.
@frozen
public struct EnvironmentKeyWritingModifier<V>: ViewModifier {

    var keyPath: WritableKeyPath<EnvironmentValues, V>
    @EnvironmentOrValue var value:V

    /// Creates a modifier that sets the environment value at `keyPath` to `value`.
    public init(
        keyPath: WritableKeyPath<EnvironmentValues, V>,
        value: V
    ) {
        self.keyPath = keyPath
        self._value = .init(value)
    }

    /// Creates a modifier that sets the environment value at `keyPath` to `value`
    /// when `isEnabled` is `true`, otherwise the inherited value is preserved.
    public init(
        keyPath: WritableKeyPath<EnvironmentValues, V>,
        value: V,
        isEnabled: Bool
    ) {
        self.keyPath = keyPath
        self._value = isEnabled ? .init(value) : .init(keyPath)
    }

    /// Creates a modifier that sets the environment value at `keyPath` to `value`
    /// when it is non-nil, otherwise the inherited value is preserved.
    public init(
        keyPath: WritableKeyPath<EnvironmentValues, V>,
        value: V?
    ) {
        self.keyPath = keyPath
        self._value = value.map { .init($0) } ?? .init(keyPath)
    }

    public func body(content: Content) -> some View {
        content
            .environment(keyPath, value)
    }
}

extension View {

    /// Sets the environment value of the specified key path to the given value
    /// when `isEnabled` is `true`, otherwise the inherited value is preserved.
    public func environment<V>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V,
        isEnabled: Bool
    ) -> some View {
        modifier(
            EnvironmentKeyWritingModifier(
                keyPath: keyPath,
                value: value,
                isEnabled: isEnabled
            )
        )
    }

    /// Sets the environment value of the specified key path to the given value
    /// when it is non-nil, otherwise the inherited value is preserved.
    @_disfavoredOverload
    public func environment<V>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V?
    ) -> some View {
        modifier(
            EnvironmentKeyWritingModifier(
                keyPath: keyPath,
                value: value
            )
        )
    }
}

// MARK: - Previews

struct EnvironmentKeyWritingModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isEnabled = false

        var body: some View {
            Button {
                withAnimation {
                    isEnabled.toggle()
                }
            } label: {
                VStack {
                    Text("Hello, World")
                        .environment(\.font, .title, isEnabled: !isEnabled)

                    Text("Hello, World")
                        .environment(\.font, .title, isEnabled: isEnabled)

                    Text("Hello, World")
                        .environment(\.font, isEnabled ? nil : .title)
                }
            }
        }
    }
}
