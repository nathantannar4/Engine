//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor @preconcurrency
public protocol PrimitiveView: View {

    @MainActor @preconcurrency static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs

    @MainActor @preconcurrency static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @MainActor @preconcurrency static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int?
}

extension PrimitiveView {

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

extension MainActor {
    static func unsafe<T>(_ body: @MainActor () throws -> T) rethrows -> T {
        #if swift(>=5.9)
        return try MainActor.assumeIsolated {
            try body()
        }
        #else
        return try body()
        #endif
    }
}
