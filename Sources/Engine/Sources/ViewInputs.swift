//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
import os.log

@frozen
public struct ViewInputs {

    @frozen
    public struct Options: OptionSet, Sendable {
        public var rawValue: UInt32

        public init(rawValue: UInt32) { self.rawValue = rawValue }

        public static func flag(_ index: Int) -> Options {
            Options(rawValue: 1 << index)
        }

        public static let isAxisDefined = Options(rawValue: 1 << 2)

        public static let isAxisHorizontal = Options(rawValue: 1 << 3)
    }

    @usableFromInline
    var customInputs: PropertyList

    public let options: Options

    @inlinable
    public init(inputs: _GraphInputs) {
        self.customInputs = inputs.customInputs
        do {
            let rawValue = try swift_getFieldValue("options", UInt32.self, inputs)
            self.options = Options(rawValue: rawValue)
        } catch {
            preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
        }
    }

    @inlinable
    public init(inputs: _ViewInputs) {
        self.init(inputs: inputs.graphInputs)
    }

    @inlinable
    public init(inputs: _ViewListInputs) {
        self.init(inputs: inputs.graphInputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public init(inputs: _ViewListCountInputs) {
        self.customInputs = inputs.customInputs
        do {
            let rawValue = try swift_getFieldValue("baseOptions", UInt32.self, inputs)
            self.options = Options(rawValue: rawValue)
        } catch {
            preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type,
        default defaultValue: @autoclosure () -> Input.Value?
    ) -> Input.Value? {
        get { customInputs[Input.self, default: defaultValue()] }
        set { customInputs[Input.self, default: defaultValue()] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
        set { customInputs[key, as: Value.self] = newValue }
    }
}

/// A `ViewModifier` that only modifies the static inputs
public protocol ViewInputsModifier: GraphInputsModifier {
    nonisolated static func makeInputs(inputs: inout ViewInputs)
}

extension ViewInputsModifier {
    public nonisolated static func makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        var modifiedInputs = ViewInputs(inputs: inputs)
        makeInputs(inputs: &modifiedInputs)
        inputs.customInputs = modifiedInputs.customInputs
    }
}

@frozen
public struct _ViewInputsLogModifier: ViewInputsModifier {

    @inlinable
    public init() { }

    public static func makeInputs(inputs: inout ViewInputs) {
        #if DEBUG
        var message = ""
        dump(inputs.options, to: &message)
        os_log(.debug, "%@", message)
        var ptr = inputs.customInputs.elements
        while let p = ptr {
            message = ""
            dump(p, to: &message)
            if case .v8 = p {
                dump(p.keyType, to: &message)
            }
            dump(p.fields, to: &message)
            if let value = p.value {
                dump(value, to: &message)
            }
            ptr = p.advanced()

            os_log(.debug, "%@", message)
        }
        #endif
    }
}

private struct PreferencesInputsLayout {

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    struct V6 {
        var keys: [any PreferenceKey.Type]
        var hostKeys: UInt32
    }
}

extension _ViewInputs {

    public var graphInputs: _GraphInputs {
        get {
            do {
                let inputs = try swift_getFieldValue("base", _GraphInputs.self, self)
                return inputs
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
        set {
            do {
                try swift_setFieldValue("base", newValue, &self)
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
    }

    public mutating func bridgeHostingView() {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            do {
                var preferences = try swift_getFieldValue("preferences", PreferencesInputsLayout.V6.self, self)
                if let key = _typeByName("7SwiftUI21AccessibilityNodesKeyV") as? any PreferenceKey.Type {
                    preferences.keys.append(key)
                } else {
                    os_log(.debug, log: .default, "Failed to bridge hosting view accessibility. Please file an issue.")
                }
                try swift_setFieldValue("preferences", preferences, &self)
            } catch {
                os_log(.debug, log: .default, "Failed to bridge hosting view with error: %{public}@. Please file an issue.", error.localizedDescription)
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { graphInputs[Input.self] }
        set { graphInputs[Input.self] = newValue }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type,
        default defaultValue: @autoclosure () -> Input.Value?
    ) -> Input.Value? {
        get { graphInputs[Input.self, default: defaultValue()] }
        set { graphInputs[Input.self, default: defaultValue()] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
        set { graphInputs[key, as: Value.self] = newValue }
    }
}

extension _ViewListInputs {

    public var graphInputs: _GraphInputs {
        get {
            do {
                let inputs = try swift_getFieldValue("base", _GraphInputs.self, self)
                return inputs
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
        set {
            do {
                try swift_setFieldValue("base", newValue, &self)
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { graphInputs[Input.self] }
        set { graphInputs[Input.self] = newValue }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type,
        default defaultValue: @autoclosure () -> Input.Value?
    ) -> Input.Value? {
        get { graphInputs[Input.self, default: defaultValue()] }
        set { graphInputs[Input.self, default: defaultValue()] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
        set { graphInputs[key, as: Value.self] = newValue }
    }
}

private struct ViewListCountInputsLayout {
    var customInputs: PropertyList
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs {

    @usableFromInline
    var customInputs: PropertyList {
        get {
            withUnsafePointer(to: self) { ptr -> PropertyList in
                ptr.withMemoryRebound(to: ViewListCountInputsLayout.self, capacity: 1) { ptr -> PropertyList in
                    ptr.pointee.customInputs
                }
            }
        }
        set {
            withUnsafeMutablePointer(to: &self) { ptr in
                ptr.withMemoryRebound(to: ViewListCountInputsLayout.self, capacity: 1) { ptr in
                    ptr.pointee.customInputs = newValue
                }
            }
        }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    public subscript<Input: ViewInputKey>(
        _ : Input.Type,
        default defaultValue: @autoclosure () -> Input.Value?
    ) -> Input.Value? {
        get { customInputs[Input.self, default: defaultValue()] }
        set { customInputs[Input.self, default: defaultValue()] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type = Value.self
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
        set { customInputs[key, as: Value.self] = newValue }
    }
}
