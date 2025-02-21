//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that reads an environment value to derive its content
@frozen
public struct EnvironmentValueReader<Value, Content: View>: View {

    @usableFromInline
    var value: Environment<Value>

    @usableFromInline
    var content: (Value) -> Content

    @inlinable
    public init(
        _ keyPath: KeyPath<EnvironmentValues, Value>,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.value = Environment(keyPath)
        self.content = content
    }

    public var body: some View {
        content(value.wrappedValue)
    }
}

// MARK: - Preview

fileprivate extension EnvironmentValues {
    var testFlag: Bool {
        get { self[EnvironmentValueReader_Preview.TestFlagKey.self] }
        set { self[EnvironmentValueReader_Preview.TestFlagKey.self] = newValue }
    }
}

struct EnvironmentValueReader_Preview: PreviewProvider {
    enum TestFlagKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    static var previews: some View {
        VStack {
            EnvironmentValueReader(\.testFlag) { flag in
                Text(flag.description)
            }

            EnvironmentValueReader(\.testFlag) { flag in
                Text(flag.description)
            }
            .environment(\.testFlag, true)
        }
    }
}
