//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``MultiViewVisitor`` allows for `some View` to be unwrapped
/// to visit the concrete `View` type for each subview.
public typealias MultiViewVisitor = EngineCore.MultiViewVisitor

/// The ``TypeDescriptor`` for the ``MultiView`` protocol.
public typealias MultiViewProtocolDescriptor = EngineCore.MultiViewProtocolDescriptor

/// A ``MultiViewVisitor`` that collects each visited subview.
@frozen
public struct MultiViewSubviewVisitor: MultiViewVisitor {

    /// A type-erased subview collected by a ``MultiViewSubviewVisitor``.
    @frozen
    public struct Subview: View, Identifiable {
        /// The identifier of the subview.
        public nonisolated(unsafe) var id: Context.ID
        /// The type-erased content of the subview.
        public nonisolated(unsafe) var content: AnyView

        nonisolated init<Content: View>(
            id: Context.ID,
            content: Content
        ) {
            self.id = id
            self.content = AnyView(content)
        }

        public var body: some View {
            content
        }
    }

    /// The subviews that have been visited, in order.
    public private(set) var subviews: [Subview] = []

    /// Creates a visitor with no collected subviews.
    @inlinable
    public init() { }

    public mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        subviews.append(Subview(id: context.id, content: content))
    }
}

extension MultiViewAdapter where Visitor == MultiViewSubviewVisitor {

    /// Creates an adapter that provides each subview of `source` to `content`.
    ///
    ///     MultiViewAdapter {
    ///         Text("Hello")
    ///         Text("World")
    ///     } content: { subviews in
    ///         ForEachSubview(subviews) { index, subview in
    ///             subview
    ///                 .border(Color.red)
    ///         }
    ///     }
    ///
    @inlinable
    public init(
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping ([Visitor.Subview]) -> Content
    ) {
        self.init(
            MultiViewSubviewVisitor(),
            source: source,
            content: { content($0.subviews) }
        )
    }
}

/// A ``MultiViewVisitor`` that determines if a view has no subviews.
@frozen
public struct MultiViewIsEmptyVisitor: MultiViewVisitor {

    /// Whether no subviews have been visited.
    public private(set) var isEmpty: Bool = true

    /// Creates a visitor that is initially empty.
    @inlinable
    public init() { }

    public mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        isEmpty = false
        stop = true
    }
}

extension MultiViewAdapter where Visitor == MultiViewIsEmptyVisitor {

    /// Creates an adapter that provides whether `source` has no subviews to `content`.
    @inlinable
    public static func isEmptyVisitor(
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping (_ isEmpty: Bool) -> Content
    ) -> some View {
        return MultiViewAdapter(
            MultiViewIsEmptyVisitor(),
            source: source,
            content: { content($0.isEmpty) }
        )
    }
}

extension View {

    /// A Boolean value indicating whether the view resolves to no subviews,
    /// such as `EmptyView` or a false conditional.
    public var isEmptyView: Bool {
        var visitor = MultiViewIsEmptyVisitor()
        visit(visitor: &visitor)
        return visitor.isEmpty
    }
}

// MARK: - Previews

struct MultiViewIsEmptyVisitor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MultiViewAdapter.isEmptyVisitor {
                EmptyView()
            } content: { isEmpty in
                Text(isEmpty.description) // true
            }
            .previewDisplayName("EmptyView")

            MultiViewAdapter.isEmptyVisitor {
                Text("Hello, World")
            } content: { isEmpty in
                Text(isEmpty.description) // false
            }
            .previewDisplayName("Text")

            let flag = false
            MultiViewAdapter.isEmptyVisitor {
                if flag {
                    Text("Hello, World")
                }
            } content: { isEmpty in
                Text(isEmpty.description) // true
            }
            .previewDisplayName("Conditional")
        }
    }
}

struct MultiViewSubviewVisitor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                MultiViewAdapter {
                    Text("Hello, World")
                } content: { subviews in
                    Text(subviews.count.description)
                    ForEachSubview(subviews) { _, subview in
                        subview
                    }
                }
            }
            .previewDisplayName("Text")

            VStack {
                MultiViewAdapter {
                    Text("Hello")
                    Text("World")
                } content: { subviews in
                    Text(subviews.count.description)
                    ForEachSubview(subviews) { _, subview in
                        subview
                    }
                }
            }
            .previewDisplayName("TupleView")

            VStack {
                MultiViewAdapter {
                    Group {
                        Text("Hello")
                        Text("World")
                    }
                } content: { subviews in
                    Text(subviews.count.description)
                    ForEachSubview(subviews) { _, subview in
                        subview
                    }
                }
            }
            .previewDisplayName("Group")

            VStack {
                MultiViewAdapter {
                    Text("Line 1")

                    Group {
                        Text("Line 2")
                        Text("Line 3")
                    }
                } content: { subviews in
                    Text(subviews.count.description)
                    ForEachSubview(subviews) { _, subview in
                        subview
                    }
                }
            }
            .previewDisplayName("TupleView + Group")

            VStack {
                MultiViewAdapter {
                    let indices = [0, 1, 2]
                    ForEach(indices, id: \.self) { index in
                        Text("Index \(index)")
                    }
                } content: { subviews in
                    Text(subviews.count.description)
                    ForEachSubview(subviews) { _, subview in
                        subview
                    }
                }
            }
            .previewDisplayName("ForEach")
        }
    }
}
