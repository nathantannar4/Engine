//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that transforms a `Source` view to `Content` using
/// a ``MultiViewVisitor``.
///
/// Most views such as `ZStack`, `VStack` and `HStack` are
/// unary views. This means they would produce a single subview
/// if transformed by a ``VariadicViewAdapter``. This is contrary
/// to `ForEach`, `TupleView`, `Section` and `Group` which
/// would produce multiple subviews. This different in behaviour can be
/// crucial, as it impacts: layout, how a view is modified by a `ViewModifier`,
/// and performance.
///
/// > Tip: In most cases you shouldn't need to use ``MultiViewAdapter``,
/// but it can help in cases where ``VariadicViewAdapter`` is insufficient.
///
/// With ``MultiViewAdapter`` the individual views can be accessed.
/// This can be particularly useful when you need to transform a collection of
/// views to UIKit/AppKit components.
///
/// ``MultiViewAdapter`` relies on the ``MultiView`` protocol which
/// a ``MultiViewVisitor`` uses to iterate over each subview.
///
@frozen
public struct MultiViewAdapter<
    Visitor: MultiViewVisitor,
    Source: View,
    Content: View
>: View {

    @usableFromInline
    var visitor: Visitor

    @usableFromInline
    var source: Source

    @usableFromInline
    var content: (Visitor) -> Content

    @inlinable
    public init(
        _ visitor: Visitor,
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping (Visitor) -> Content
    ) {
        self.visitor = visitor
        self.source = source()
        self.content = content
    }

    // MARK: View

    public var body: some View {
        var visitor = visitor
        source.visit(visitor: &visitor)
        return content(visitor)
    }
}

// MARK: - Previews

struct MultiViewAdapter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MultiViewAdapter {
                Text("Hello")
                Text("World")
            } content: { subviews in
                ForEachSubview(subviews) { index, subview in
                    subview
                        .border(Color.red)
                }
            }
        }
        .previewDisplayName("TupleView")

        VStack {
            MultiViewAdapter {
                Section {
                    Text("Content")
                } header: {
                    Text("Header")
                } footer: {
                    Text("Footer")
                }
            } content: { subviews in
                ForEachSubview(subviews) { index, subview in
                    subview
                        .border(Color.red)
                }
            }
        }
        .previewDisplayName("Section")
    }
}
