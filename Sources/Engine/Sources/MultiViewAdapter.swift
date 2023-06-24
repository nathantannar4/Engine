//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that wraps `Content` in a multi view.
///
/// Most views such as `ZStack`, `VStack` and `HStack` are
/// unary views. This means they would produce a single subview
/// if transformed by a ``VariadicViewAdapter``. This is contrary
/// to `TupleView` and `Group` which would produce multiple
/// subviews. This different in behaviour can be crucial, as it impacts:
/// layout, how a view is modified by a `ViewModifier`, and
/// performance.
///
/// > Tip: In most cases you shouldn't need to use ``MultiViewAdapter``,
/// but it can be used to ensure you're working with a multi view.
///
/// With ``MultiViewAdapter`` the individual views can be accessed
/// by an index. This can be particularly useful when you need to transform a
/// collection of views to a `UIViewController` when bridging to UIKit
/// components.
///
///  ``MultiViewAdapter`` relies on the ``MultiView`` protocol which
///  a ``MultiViewVisitor`` uses to iterate over each subview.
///
@frozen
public struct MultiViewAdapter<Content: View & MultiView>: View {

    @usableFromInline
    var content: Content

    @inlinable
    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    @_disfavoredOverload
    @inlinable
    public init<UnaryContent: View>(
        @ViewBuilder content: () -> UnaryContent
    ) where Content == TupleView<UnaryContent> {
        self.content = TupleView(content())
    }

    // MARK: Collection

    public typealias Element = AnyView
    public typealias Iterator = Content.Iterator
    public typealias Index = Content.Index

    public func makeIterator() -> Iterator {
        content.makeIterator()
    }

    public var startIndex: Index {
        return content.startIndex
    }

    public var endIndex: Index {
        return content.endIndex
    }

    public subscript(position: Index) -> Element {
        return AnyView(visiting: content[position])!
    }

    public var subviews: [Element] {
        return content.subviews
    }

    // MARK: View

    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Content._makeView(view: view[\.content], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Content._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
}

// MARK: - Previews

struct MultiViewAdapter_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            ZStack {
                makeView {
                    Color.red

                    Text("Hello, World")
                }
            }
        }

        func makeView<Content: View & MultiView>(
            @ViewBuilder content: () -> Content
        ) -> some View {
            let adapter = MultiViewAdapter(content: content)
            return adapter
        }
    }

    static var previews: some View {
        Group {
            HStack {
                let adapter = MultiViewAdapter {
                    Text("Hello, World")
                }
                Text(adapter.endIndex.description)

                VStack {
                    adapter
                }
            }
            .previewDisplayName("Text")

            HStack {
                let adapter = MultiViewAdapter {
                    Text("Hello")
                    Text("World")
                }
                Text(adapter.endIndex.description)

                VStack {
                    adapter
                }
            }
            .previewDisplayName("TupleView")

            HStack {
                let adapter = MultiViewAdapter {
                    Group {
                        Text("Line 1")
                        Text("Line 2")
                    }
                }
                Text(adapter.endIndex.description)

                VStack {
                    adapter
                }
            }
            .previewDisplayName("Group")

            HStack {
                let adapter = MultiViewAdapter {
                    Text("Line 1")

                    Group {
                        Text("Line 2")
                        Text("Line 3")
                    }
                }
                Text(adapter.endIndex.description)

                VStack {
                    adapter
                }
            }
            .previewDisplayName("TupleView + Group")

            HStack {
                let adapter = MultiViewAdapter {
                    let indices = [0, 1, 2]
                    ForEach(indices, id: \.self) { index in
                        Text("Index \(index)")
                    }
                }
                Text(adapter.endIndex.description)

                VStack {
                    adapter
                }
            }
            .previewDisplayName("ForEach")
        }
    }
}
