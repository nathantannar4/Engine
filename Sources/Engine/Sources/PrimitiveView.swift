//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor @preconcurrency
public protocol PrimitiveView: View, DynamicProperty {

    nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs

    nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs

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
