//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A wrapper for `@ViewBuilder`
@frozen
public struct ViewAdapter<Content: View>: PrimitiveView {

    @usableFromInline
    var content: Content

    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Content._makeView(view: view[\.content], inputs: inputs)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Content._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
}
