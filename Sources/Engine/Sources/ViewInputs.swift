//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
import os.log

public struct ViewInputs {

    public struct Options: OptionSet, Sendable {
        public var rawValue: UInt32

        public init(rawValue: UInt32) { self.rawValue = rawValue }

        public static func flag(_ index: Int) -> Options {
            Options(rawValue: 1 << index)
        }

        public static let isAxisDefined = Options(rawValue: 1 << 2)

        public static let isAxisHorizontal = Options(rawValue: 1 << 3)
    }

    var customInputs: PropertyList

    public let options: Options

    init(inputs: _GraphInputs) {
        self.customInputs = inputs.customInputs
        do {
            let rawValue = try swift_getFieldValue("options", UInt32.self, inputs)
            self.options = Options(rawValue: rawValue)
        } catch {
            preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
        }
    }

    init(inputs: _ViewInputs) {
        self.init(inputs: inputs.graphInputs)
    }

    init(inputs: _ViewListInputs) {
        self.init(inputs: inputs.graphInputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    init(inputs: _ViewListCountInputs) {
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

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
    }

    public subscript<Value>(
        key: String
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
        set { customInputs[key] = newValue }
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
            dump(p.fields, to: &message)
            dump(p.value, to: &message)
            ptr = p.after

            os_log(.debug, "%@", message)
        }
        #endif
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

    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value {
        get { graphInputs[Input.self] }
        set { graphInputs[Input.self] = newValue }
    }

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { graphInputs[Input.self] }
        set { graphInputs[Input.self] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
    }

    public subscript<Value>(
        key: String
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
        set { graphInputs[key] = newValue }
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

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { graphInputs[Input.self] }
        set { graphInputs[Input.self] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
    }

    public subscript<Value>(
        key: String
    ) -> Value? {
        get { graphInputs[key, as: Value.self] }
        set { graphInputs[key] = newValue }
    }
}

private struct ViewListCountInputsLayout {
    var customInputs: PropertyList
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs {

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

    @_disfavoredOverload
    public subscript<Input: ViewInputKey>(
        _ : Input.Type
    ) -> Input.Value? {
        get { customInputs[Input.self] }
        set { customInputs[Input.self] = newValue }
    }

    public subscript<Value>(
        key: String,
        as _: Value.Type
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
    }

    public subscript<Value>(
        key: String
    ) -> Value? {
        get { customInputs[key, as: Value.self] }
        set { customInputs[key] = newValue }
    }
}
