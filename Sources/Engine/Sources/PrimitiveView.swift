//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A protocol for views that build their outputs directly from the
/// SwiftUI view graph, rather than from a `body`.
///
/// Conforming types implement the graph hooks below, which are forwarded
/// from SwiftUI's underscored `View` requirements. When `Body` is `Never`,
/// a default `body` is provided that traps if called.
public protocol PrimitiveView: View, DynamicProperty {

    /// Makes the view outputs for the view.
    nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs

    /// Makes the view list outputs for the view.
    nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs

    /// Returns the number of views the view produces in a view list, if known statically.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int?
}

extension PrimitiveView where Body == Never {
    
    public var body: Never {
        bodyError()
    }
}

extension PrimitiveView {

    public nonisolated static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        makeView(view: view, inputs: inputs)
    }

    public nonisolated static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        makeViewList(view: view, inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        viewListCount(inputs: inputs)
    }
}
