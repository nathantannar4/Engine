//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
import os.log

public struct ViewInputs {

    public struct Options: OptionSet {
        public var rawValue: UInt32

        public init(rawValue: UInt32) { self.rawValue = rawValue }

        public static func flag(_ index: Int) -> Options {
            Options(rawValue: 1 << index)
        }

        public static let isAxisHorizontal = Options(rawValue: 1 << 3)
    }

    var customInputs: PropertyList

    public var options: Options

    init<Inputs: _CustomInputsProvider>(inputs: Inputs) {
        self.customInputs = inputs.customInputs
        do {
            let rawValue = try swift_getFieldValue("options", UInt32.self, inputs)
            self.options = Options(rawValue: rawValue)
        } catch {
            self.options = Options(rawValue: 0)
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
        _: Value.Type
    ) -> Value? {
        get { customInputs[key, Value.self] }
    }
}

/// A `ViewModifier` that only modifies the static inputs
public protocol ViewInputsModifier: GraphInputsModifier {
    static func makeInputs(inputs: inout ViewInputs)
}

extension ViewInputsModifier {
    public static func makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        withUnsafeMutablePointer(to: &inputs) { ptr in
            ptr.withMemoryRebound(to: ViewInputs.self, capacity: 1) { ptr in
                makeInputs(inputs: &ptr.pointee)
            }
        }
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

extension _ViewInputs: _CustomInputsProvider {

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
        _: Value.Type
    ) -> Value? {
        get { customInputs[key, Value.self] }
    }
}

extension _ViewListInputs: _CustomInputsProvider {

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
        _: Value.Type
    ) -> Value? {
        get { customInputs[key, Value.self] }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs: _CustomInputsProvider {

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
        _: Value.Type
    ) -> Value? {
        get { customInputs[key, Value.self] }
    }
}
