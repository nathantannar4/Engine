//
// Copyright (c) Nathan Tannar
//

import SwiftUI

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
@frozen
public struct UnaryViewAdaptor<Content: View>: View {

    @usableFromInline
    var content: Content

    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        _UnaryViewAdaptor(content)
    }
}
