//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor @preconcurrency
public protocol PrimitiveView: View where Body == Never {

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

extension PrimitiveView where Body == Never {

    public var body: Never {
        bodyError()
    }

    private var modifier: UnaryViewModifier { .init() } // workaround crashes

    public nonisolated static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        MainActor.unsafe {
            UnaryViewModifier._makeView(modifier: view[\.modifier], inputs: inputs) { _, inputs in
                makeView(view: view, inputs: inputs)
            }
        }
    }

    public nonisolated static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        MainActor.unsafe {
            UnaryViewModifier._makeViewList(modifier: view[\.modifier], inputs: inputs) { _, inputs in
                makeViewList(view: view, inputs: inputs)
            }
        }
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        MainActor.unsafe {
            UnaryViewModifier._viewListCount(inputs: inputs) { inputs in
                viewListCount(inputs: inputs)
            }
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
