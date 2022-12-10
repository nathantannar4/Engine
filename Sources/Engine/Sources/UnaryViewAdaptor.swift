//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that wraps `Content` in unary view.
///
/// Most views such as `ZStack`, `VStack` and `HStack` are
/// unary views. This means they would produce a single subview
/// if transformed by a ``VariadicViewAdapter``. This is contrary
/// to `TupleView` and `Group` which would produce multiple
/// subviews. This different in behaviour can be crucial, as it impacts:
/// layout, how a view is modified by a `ViewModifier`, and
/// performance.
///
/// > Tip: In most cases you shouldn't need to use ``UnaryViewAdaptor``,
/// but it can help fix rare performance problems or layout crashes.
///
/// For example a unary view will result in a single subview when used as
/// the source for a ``VariadicViewAdapter``. Whereas a `TupleView`
/// would result in N subviews, one for each element in the tuple.
/// 
@frozen
public struct UnaryViewAdaptor<Content: View>: View {

    @usableFromInline
    var content: _UnaryViewAdaptor<Content>

    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = _UnaryViewAdaptor(content())
    }

    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        _UnaryViewAdaptor<Content>._makeView(view: view[\.content], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        _UnaryViewAdaptor<Content>._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        _UnaryViewAdaptor<Content>._viewListCount(inputs: inputs)
    }
}
