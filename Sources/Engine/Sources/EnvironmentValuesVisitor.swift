//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
import os.log

extension EnvironmentValues {

    /// Visit the `EnvironmentKey` type that matches the key
    ///
    ///     extension EnvironmentValues {
    ///         var foregroundStyle: AnyShapeStyle? {
    ///             self["ForegroundStyleKey"]
    ///         }
    ///     }
    ///
    ///     struct ContentView: View {
    ///         @Environment(\.foregroundStyle) var foregroundStyle
    ///
    ///         var body: some View {
    ///             Text("Hello, World")
    ///                 .foregroundColor(.white)
    ///                 .padding()
    ///                 .background(
    ///                     Capsule()
    ///                         .fill(foregroundStyle ?? AnyShapeStyle(.foreground))
    ///                 )
    ///         }
    ///     }
    ///
    public subscript<Value>(
        _ key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        value(for: key, as: Value.self)
    }

    /// Visit the `EnvironmentKey` type that matches the key
    ///
    ///     extension EnvironmentValues {
    ///         var foregroundStyle: AnyShapeStyle {
    ///             self["ForegroundStyleKey", default: AnyShapeStyle(.foreground)]
    ///         }
    ///     }
    ///
    ///     struct ContentView: View {
    ///         @Environment(\.foregroundStyle) var foregroundStyle
    ///
    ///         var body: some View {
    ///             Text("Hello, World")
    ///                 .foregroundColor(.white)
    ///                 .padding()
    ///                 .background(
    ///                     Capsule()
    ///                         .fill(foregroundStyle)
    ///                 )
    ///         }
    ///     }
    ///
    public subscript<Value>(
        _ key: String,
        as _: Value.Type = Value.self,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        value(for: key, as: Value.self) ?? defaultValue()
    }

    /// Visit the `EnvironmentKey` type that matches the key to get the value
    public func value<Value>(
        for key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        visit("EnvironmentPropertyKey<\(key)>") { conformance in
            conformance.value(in: self, as: Value.self)
        }
    }

    /// Visit the `EnvironmentKey` type that matches the key to set the value
    ///
    /// > Warning: Only works if `EnvironmentKey` exists
    @discardableResult
    public mutating func setValue<Value>(
        _ value: Value,
        for key: String
    ) -> Bool {
        let didSet = visit("EnvironmentPropertyKey<\(key)>") { conformance in
            conformance.setValue(value, in: &self)
        }
        return didSet ?? false
    }

    fileprivate func visit<Result>(
        _ key: String,
        body: (ProtocolConformance<EnvironmentKeyProtocolDescriptor>) -> Result?
    ) -> Result? {

        if let conformance = EnvironmentKeyLookupCache.shared[key] {
            return body(conformance)
        }

        var ptr = plist.elements
        while let p = ptr {
            let typeName = _typeName(p.keyType, qualified: false)
            var isMatch = typeName == key
            if !isMatch, typeName == "EnvironmentPropertyKey<Key>" {
                let qualifiedTypeName = _typeName(p.keyType, qualified: true)
                    .replacingOccurrences(of: "SwiftUI.", with: "")
                isMatch = qualifiedTypeName == key
            }
            if isMatch {
                guard
                    let environmentKey = swift_getStructGenerics(for: p.keyType)?.first,
                    let conformance = EnvironmentKeyProtocolDescriptor.conformance(of: environmentKey)
                else {
                    return nil
                }
                EnvironmentKeyLookupCache.shared[key] = conformance
                return body(conformance)
            }
            ptr = p.after
        }
        return nil
    }
}

extension EnvironmentValues {
    fileprivate var plist: PropertyList {
        guard let plistValue = try? swift_getFieldValue("_plist", Any.self, self)
        else {
            return PropertyList(ptr: nil)
        }
        func project<T>(_ value: T) -> PropertyList {
            unsafeBitCast(value, to: PropertyList.self)
        }
        let plist = _openExistential(plistValue, do: project)
        return plist
    }
}

extension ProtocolConformance where P == EnvironmentKeyProtocolDescriptor {

    fileprivate func value<Value>(
        in environment: EnvironmentValues,
        as _: Value.Type = Value.self
    ) -> Value? {
        var visitor = EnvironmentValuesGetterVisitor<Value>(
            environment: environment
        )
        visit(visitor: &visitor)
        return visitor.output
    }

    fileprivate func setValue<Value>(
        _ value: Value,
        in environment: inout EnvironmentValues
    ) -> Bool {
        var visitor = EnvironmentValuesSetterVisitor<Value>(
            environment: environment,
            value: value
        )
        visit(visitor: &visitor)
        if visitor.output {
            environment = visitor.environment
        }
        return visitor.output
    }
}

private struct EnvironmentValuesGetterVisitor<Value>: EnvironmentKeyVisitor {
    var environment: EnvironmentValues
    var output: Value?

    mutating func visit<Key: EnvironmentKey>(type: Key.Type) {
        let value = environment[Key.self]
        if Key.Value.self == Value.self {
            output = value as? Value
        } else if Value.self == Any.self {
            output = (value as Any) as? Value
        } else if MemoryLayout<Key.Value>.size == MemoryLayout<Value>.size {
            output = unsafeBitCast(value, to: Value.self)
        }
    }
}

private struct EnvironmentValuesSetterVisitor<Value>: EnvironmentKeyVisitor {
    var environment: EnvironmentValues
    var value: Value
    var output: Bool = false

    mutating func visit<Key: EnvironmentKey>(type: Key.Type) {
        if let value = value as? Key.Value {
            environment[Key.self] = value
            output = true
        } else if MemoryLayout<Key.Value>.size == MemoryLayout<Value>.size {
            environment[Key.self] = unsafeBitCast(value, to: Key.Value.self)
            output = true
        }
    }
}

private class EnvironmentKeyLookupCache: @unchecked Sendable {

    private let lock: os_unfair_lock_t
    private var storage = [String: ProtocolConformance<EnvironmentKeyProtocolDescriptor>]()

    static let shared = EnvironmentKeyLookupCache()
    private init() {
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock_s())
    }

    subscript(_ key: String) -> ProtocolConformance<EnvironmentKeyProtocolDescriptor>? {
        get {
            storage[key]
        }
        set {
            os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(lock) }
            storage[key] = newValue
        }
    }
}

@frozen
public struct _EnvironmentValuesLogModifier: ViewModifier {

    #if DEBUG
    @Environment(\.self) var environment
    #endif

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            #if DEBUG
            .onAppear {
                let log: String = {
                    var message = "\n=== EnvironmentValues ===\n"
                    let environment = environment
                    var ptr = environment.plist.elements
                    while let p = ptr {
                        let keyType = _typeName(p.keyType, qualified: false)
                        let value = environment.visit(keyType) { conformance in
                            conformance.value(in: environment, as: Any.self)
                        }
                        message += """
                        \(keyType)
                            ▿ value: \(value ?? "nil")\n
                        """
                        ptr = p.after
                    }
                    return message
                }()
                os_log(.debug, "%@", log)
            }
            #endif
    }
}
