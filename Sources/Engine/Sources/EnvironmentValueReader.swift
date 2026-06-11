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
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false
        @State var value = 0

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { EmptyView() }
                    .labelsHidden()

                Button("\(value)") {
                    value += 1
                }

                EnvironmentValueReader(\.testFlag) { flag in
                    Text(flag.description)
                }

                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    EnvironmentValueReader(\.testFlag) { flag in
                        ChildView(flag: flag)
                    }
                }
            }
            .environment(\.testFlag, flag)
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        struct ChildView: View {
            var flag: Bool

            var body: some View {
                let _ = Self._printChanges()
                Text(flag.description)
            }
        }
    }
}
