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
    ///                         .fill(foregroundStyle ?? AnyShapeStyle(.tint))
    ///                 )
    ///         }
    ///     }
    ///
    public subscript<Value>(
        _ key: String
    ) -> Value? {
        visit("EnvironmentPropertyKey<\(key)>")
    }

    /// Visit the `EnvironmentKey` type that matches the key
    ///
    ///     extension EnvironmentValues {
    ///         var foregroundStyle: AnyShapeStyle {
    ///             self["ForegroundStyleKey", default: AnyShapeStyle(.tint)]
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
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        visit(key, default: defaultValue())
    }

    /// Visit the `EnvironmentKey` type that matches the key
    ///
    ///     extension EnvironmentValues {
    ///         var accentColor: Any {
    ///             self["AccentColorKey", as: Any.self, default: nil]
    ///         }
    ///     }
    ///
    public func visit<Value>(
        _ key: String,
        as _: Value.Type = Value.self,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        visit("EnvironmentPropertyKey<\(key)>", as: Value.self) ?? defaultValue()
    }

    fileprivate func visit<Value>(
        _ key: String,
        as _: Value.Type = Value.self
    ) -> Value? {

        if let conformance = EnvironmentKeyLookupCache.shared[key] {
            return conformance.value(in: self)
        }

        var ptr = plist.elements
        while let p = ptr {
            let typeName = _typeName(p.pointee.fields.keyType, qualified: false)
            if typeName == key {
                guard
                    let environmentKey = swift_getStructGenerics(for: p.pointee.fields.keyType)?.first,
                    let conformance = EnvironmentKeyProtocolDescriptor.conformance(of: environmentKey)
                else {
                    return nil
                }
                EnvironmentKeyLookupCache.shared[key] = conformance
                return conformance.value(in: self)
            }
            ptr = p.pointee.fields.after
        }
        return nil
    }
}

extension EnvironmentValues {
    fileprivate var plist: PropertyList {
        guard let plistValue = try? swift_getFieldValue("_plist", Any.self, self)
        else {
            return PropertyList(elements: nil)
        }
        func project<T>(_ value: T) -> PropertyList {
            unsafeBitCast(value, to: PropertyList.self)
        }
        let plist = _openExistential(plistValue, do: project)
        return plist
    }
}

extension ProtocolConformance where P == EnvironmentKeyProtocolDescriptor {
    fileprivate func value<Value>(in environment: EnvironmentValues) -> Value? {
        var visitor = EnvironmentValuesVisitor(environment: environment)
        visit(visitor: &visitor)
        return visitor.output as? Value
    }
}

private struct EnvironmentValuesVisitor: EnvironmentKeyVisitor {
    var environment: EnvironmentValues
    var output: Any?

    mutating func visit<Key: EnvironmentKey>(type: Key.Type) {
        output = environment[Key.self]
    }
}

private class EnvironmentKeyLookupCache {

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
                    var ptr = environment.plist.elements
                    while let p = ptr {
                        let keyType = _typeName(p.pointee.fields.keyType, qualified: false)
                        let value = environment.visit(keyType, as: Any.self)
                        message += """
                        \(keyType)
                            ▿ value: \(value ?? "nil")\n
                        """
                        ptr = p.pointee.fields.after
                    }
                    return message
                }()
                os_log(.debug, "%@", log)
            }
            #endif
    }
}
