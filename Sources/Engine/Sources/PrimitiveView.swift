//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor @preconcurrency
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

extension PrimitiveView where Body == Never {

    public var body: Never {
        bodyError()
    }

    public nonisolated static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        MainActor.unsafe {
            makeView(view: view, inputs: inputs)
        }
    }

    public nonisolated static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        MainActor.unsafe {
            makeViewList(view: view, inputs: inputs)
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        MainActor.unsafe {
            viewListCount(inputs: inputs)
        }
    }
}
