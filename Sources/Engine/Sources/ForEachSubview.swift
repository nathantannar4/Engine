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

    public var body: some View {
        let subviews = Array(zip(source.indices, source))
        ForEach(subviews, id: \.1.id) { index, element in
            subview(index, element)
        }
    }
}
