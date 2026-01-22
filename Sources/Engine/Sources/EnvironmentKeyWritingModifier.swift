//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct EnvironmentKeyWritingModifier<V>: ViewModifier {

    var keyPath: WritableKeyPath<EnvironmentValues, V>
    @EnvironmentOrValue var value:V

    public init(
        keyPath: WritableKeyPath<EnvironmentValues, V>,
        value: V
    ) {
        self.keyPath = keyPath
        self._value = .init(value)
    }

    public init(
        keyPath: WritableKeyPath<EnvironmentValues, V>,
        value: V,
        isEnabled: Bool
    ) {
        self.keyPath = keyPath
        self._value = isEnabled ? .init(value) : .init(keyPath)
    }

    public func body(content: Content) -> some View {
        content
            .environment(keyPath, value)
    }
}

extension View {

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
                }
            }
        }
    }
}
