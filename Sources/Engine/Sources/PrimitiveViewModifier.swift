//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A protocol for view modifiers that build their outputs directly from the
/// SwiftUI view graph, rather than from `body(content:)`.
///
/// Conforming types implement the graph hooks below, which are forwarded
/// from SwiftUI's underscored `ViewModifier` requirements. When `Body` is
/// `Never`, a default `body(content:)` is provided that traps if called.
public protocol PrimitiveViewModifier: ViewModifier, DynamicProperty {

    /// Makes the view outputs for the modifier, using `body` to make the
    /// outputs of the modified content.
    nonisolated static func makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs

    /// Makes the view list outputs for the modifier, using `body` to make the
    /// outputs of the modified content.
    nonisolated static func makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs

    /// Returns the number of views the modifier produces in a view list, if
    /// known statically, using `body` to count the modified content.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    nonisolated static func viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int?
}

extension PrimitiveViewModifier where Body == Never {

    public func body(content: Content) -> Never {
        bodyError()
    }
}

extension PrimitiveViewModifier {

    public nonisolated static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        makeView(modifier: modifier, inputs: inputs, body: body)
    }

    public nonisolated static func _makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        makeViewList(modifier: modifier, inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func _viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        viewListCount(inputs: inputs, body: body)
    }
}
