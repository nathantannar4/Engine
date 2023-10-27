//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that's `Body` is `Never`
///
/// > Important: This expects the use of `View`'s `makeView` protocol methods
public protocol PrimitiveView: View where Body == Never {
    static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs

    static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int?
}

extension PrimitiveView {
    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        _makeView(view: view, inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        _makeViewList(view: view, inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        viewListCount(inputs: inputs)
    }
}

extension View where Body == Never {
    @_transparent
    public func bodyError() -> Never {
        fatalError("body() should not be called on \(String(describing: Self.self))")
    }
}

/// A `ViewModifier` that's `Body` is `Never`
///
/// > Important: This expects the use of `ViewModifier`'s `makeView` protocol methods
public protocol PrimitiveViewModifier: ViewModifier where Body == Never {
    static func makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs

    static func makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    static func viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int?
}

extension PrimitiveViewModifier {
    public func body(content: Content) -> Never {
        bodyError()
    }

    public static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        makeView(modifier: modifier, inputs: inputs, body: body)
    }

    public static func _makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        makeViewList(modifier: modifier, inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        viewListCount(inputs: inputs, body: body)
    }
}

extension ViewModifier where Body == Never {
    @_transparent
    public func bodyError() -> Never {
        fatalError("body(content:) should not be called on \(String(describing: Self.self))")
    }
}
