//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that transforms a each variadic view subview
///
/// > Important: You must specify `id` key path if maintaining
/// the source view identity is neccesary
///
@frozen
public struct ForEachSubview<
    Subview: View & Identifiable,
    ID: Hashable,
    Content: View
>: View {

    @usableFromInline
    var source: Array<Subview>

    @usableFromInline
    var id: KeyPath<Subview, ID>

    @usableFromInline
    var content: (Int, Subview) -> Content

    public init(
        _ source: VariadicView,
        id: KeyPath<Subview, ID> = \.id,
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == VariadicView.Subview {
        self.source = source.filter { $0.hasID(keyPath: id) }
        self.id = id
        self.content = content
    }

    public init(
        _ source: [VariadicView.Subview],
        id: KeyPath<Subview, ID> = \.id,
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == VariadicView.Subview {
        self.source = source.filter { $0.hasID(keyPath: id) }
        self.id = id
        self.content = content
    }

    public init(
        _ source: [MultiViewSubviewVisitor.Subview],
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview, ID == Subview.ID {
        self.source = source
        self.id = \.id
        self.content = content
    }

    @_disfavoredOverload
    public init<Source: View>(
        _ source: Source,
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview, ID == Subview.ID {
        var visitor = MultiViewSubviewVisitor()
        source.visit(visitor: &visitor)
        self.init(visitor.subviews, content: content)
    }

    public var body: some View {
        ForEach(source, id: id) { index, element in
            content(index, element)
        }
    }
}

// MARK: - Previews

struct ForEachSubview_Previews: PreviewProvider {

    struct TextViews: View {
        var body: some View {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        }
    }

    static var previews: some View {
        ZStack {
            VStack {
                ForEachSubview(TextViews()) { index, subview in
                    subview
                        .border(Color.red)
                }
            }
        }
        .previewDisplayName("TupleView")

        ZStack {
            VStack {
                VariadicViewAdapter {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                } content: { content in
                    ForEachSubview(content) { _, subview in
                        HStack {
                            Text(verbatim: "\(subview.id)")

                            subview
                                .border(Color.red)
                        }
                    }
                }
            }
        }
        .previewDisplayName("ImplicitID")

        ZStack {
            VStack {
                VariadicViewAdapter {
                    Text("Line 1").id(1)
                    Text("Line 2").id(2)
                    Text("Line 3").id(3)
                } content: { content in
                    ForEachSubview(content) { _, subview in
                        HStack {
                            Text(verbatim: "\(subview.selection(as: Int.self) ?? -1)")

                            Text(verbatim: "\(subview.id(as: Int.self) ?? -1)")

                            subview
                                .border(Color.red)
                        }
                    }
                }
            }
        }
        .previewDisplayName("Int ID")

        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            ZStack {
                VStack {
                    VariadicViewAdapter {
                        Text("Line 1").tag(1)
                        Text("Line 2").tag(2)
                        Text("Line 3").tag(3)
                    } content: { content in
                        ForEachSubview(content) { _, subview in
                            HStack {
                                Text(verbatim: "\(subview.selection(as: Int.self) ?? -1)")

                                Text(verbatim: "\(subview.tag(as: Int.self) ?? -1)")

                                subview
                                    .border(Color.red)
                            }
                        }
                    }
                }
            }
            .previewDisplayName("Int Tag")

            ZStack {
                VStack {
                    VariadicViewAdapter {
                        Text("Line 1").id(1)
                        Text("Line 2").id(2)
                        Text("Line 3").id(3)
                        Text("Line 4").tag(4)
                        Text("Line 5").tag("other") // Filtered out
                    } content: { content in
                        VariadicViewAdapter {
                            ForEachSubview(
                                content,
                                id: .selection(Int.self)
                            ) { _, subview in
                                subview
                                    .border(Color.red)
                            }
                        } content: { content in
                            ForEachSubview(content) { _, subview in
                                HStack {
                                    Text(verbatim: "\(subview.selection(as: Int.self) ?? -1)")

                                    Text(verbatim: "\(subview.id(as: Int.self) ?? -1)")

                                    Text(verbatim: "\(subview.tag(as: Int.self) ?? -1)")

                                    subview
                                        .border(Color.red)
                                }
                            }
                        }
                    }
                }
            }
            .previewDisplayName("Int Selection (ID/Tag)")
        }
    }
}
