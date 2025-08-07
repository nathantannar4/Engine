//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``MultiViewVisitor`` allows for `some View` to be unwrapped
/// to visit the concrete `View` type for each subview.
public typealias MultiViewVisitor = EngineCore.MultiViewVisitor

/// The ``TypeDescriptor`` for the ``MultiView`` protocol
public typealias MultiViewProtocolDescriptor = EngineCore.MultiViewProtocolDescriptor

@frozen
public struct MultiViewSubviewVisitor: MultiViewVisitor {
    @frozen
    public struct Subview: View, Identifiable {
        public nonisolated(unsafe) var id: Context.ID
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

    public private(set) var subviews: [Subview] = []

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

@frozen
public struct MultiViewIsEmptyVisitor: MultiViewVisitor {

    public private(set) var isEmpty: Bool = true

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
