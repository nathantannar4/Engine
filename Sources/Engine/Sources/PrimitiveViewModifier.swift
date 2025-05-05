//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor @preconcurrency
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

extension PrimitiveViewModifier where Body == Never {

    public func body(content: Content) -> Never {
        bodyError()
    }

    public nonisolated static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        MainActor.unsafe {
            makeView(modifier: modifier, inputs: inputs, body: body)
        }
    }

    public nonisolated static func _makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        MainActor.unsafe {
            makeViewList(modifier: modifier, inputs: inputs, body: body)
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func _viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        MainActor.unsafe {
            viewListCount(inputs: inputs, body: body)
        }
    }
}
