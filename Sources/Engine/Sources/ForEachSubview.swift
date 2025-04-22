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
    var subview: (Int, Subview) -> Content

    public init<Source: View>(
        _ source: VariadicView<Source>,
        @ViewBuilder subview: @escaping (Int, Subview) -> Content
    ) where Subview == AnyVariadicView.Subview {
        self.init(source.children.map { $0 }, subview: subview)
    }

    public init(
        _ source: [AnyVariadicView.Subview],
        @ViewBuilder subview: @escaping (Int, Subview) -> Content
    ) where Subview == AnyVariadicView.Subview {
        self.source = source
        self.subview = subview
    }

    public init(
        _ source: [MultiViewSubviewVisitor.Subview],
        @ViewBuilder subview: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview {
        self.source = source
        self.subview = subview
    }

    @_disfavoredOverload
    public init<Source: View>(
        _ source: Source,
        @ViewBuilder subview: @escaping (Int, Subview) -> Content
    ) where Subview == MultiViewSubviewVisitor.Subview {
        var visitor = MultiViewSubviewVisitor()
        source.visit(visitor: &visitor)
        self.init(visitor.subviews, subview: subview)
    }

    public var body: some View {
        let subviews = Array(zip(source.indices, source))
        ForEach(subviews, id: \.1.id) { index, element in
            subview(index, element)
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
