//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that transforms a each variadic view subview
@frozen
public struct ForEachSubview<
    Subview: View & Identifiable,
    Content: View
>: View {

    @usableFromInline
    var source: Array<Subview>

    @usableFromInline
    var content: (Int, Subview) -> Content

    public init(
        _ source: VariadicView,
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == VariadicView.Subview {
        self.init(source.map { $0 }, content: content)
    }

    public init(
        _ source: [VariadicView.Subview],
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == VariadicView.Subview {
        self.source = source
        self.content = content
    }

    public init(
        _ source: [MultiViewSubviewVisitor.Subview],
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview {
        self.source = source
        self.content = content
    }

    @_disfavoredOverload
    public init<Source: View>(
        _ source: Source,
        @ViewBuilder content: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview {
        var visitor = MultiViewSubviewVisitor()
        source.visit(visitor: &visitor)
        self.init(visitor.subviews, content: content)
    }

    public var body: some View {
        let subviews = Array(zip(source.indices, source))
        ForEach(subviews, id: \.1.id) { index, element in
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
        VStack {
            ForEachSubview(TextViews()) { index, subview in
                subview
                    .border(Color.red)
            }
        }
    }
}
