//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A property wrapper that reads a value from a view's environment,
/// if it was not initialized with a constant value.
@propertyWrapper
@frozen
public struct EnvironmentOrValue<Value>: DynamicProperty {

    @usableFromInline
    enum Storage: DynamicProperty {
        case environment(Environment<Value>)
        case value(Value)
    }

    @usableFromInline
    var storage: Storage

    /// Creates a property that always returns the given constant value.
    @inlinable
    public init(_ value: Value) {
        self.storage = .value(value)
    }

    /// Creates a property that reads the value from the environment at `keyPath`.
    @inlinable
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.storage = .environment(.init(keyPath))
    }

    /// Creates a property that returns `value` when it is non-nil, otherwise
    /// reads the value from the environment at `keyPath`.
    @inlinable
    public init(_ value: Value?, _ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.storage = value.map({ .value($0) }) ?? .environment(.init(keyPath))
    }

    /// The constant value, or the current value from the environment.
    ///
    /// Setting the value replaces any environment lookup with a constant value.
    @inlinable
    public var wrappedValue: Value {
        get {
            switch storage {
            case .environment(let environment):
                return environment.wrappedValue
            case .value(let value):
                return value
            }
        }
        set {
            storage = .value(newValue)
        }
    }

    /// Whether the property holds a constant value rather than reading from the environment.
    @inlinable
    public var isValue: Bool {
        switch storage {
        case .environment:
            return false
        case .value:
            return true
        }
    }
}

extension EnvironmentOrValue: Sendable where Value: Sendable { }
extension EnvironmentOrValue.Storage: Sendable where Value: Sendable { }

// MARK: - Previews

extension EnvironmentValues {
    fileprivate var test: String {
        get { self[EnvironmentOrValue_Previews.TestKey.self] }
        set { self[EnvironmentOrValue_Previews.TestKey.self] = newValue }
    }
}

struct EnvironmentOrValue_Previews: PreviewProvider {
    enum TestKey: EnvironmentKey {
        static let defaultValue = "default"
    }

    struct Preview: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("Value:")

                ChildView(value: .init("Constant Value"))

                ChildView(value: .init("Constant Value", \.test))

                Text("Environment:")

                ChildView(value: .init(\.test))
                    .environment(\.test, "test")

                ChildView(value: .init(nil, \.test))
                    .environment(\.test, "test")
            }
        }

        struct ChildView: View {
            @EnvironmentOrValue var value: String

            var body: some View {
                Text(value)
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
