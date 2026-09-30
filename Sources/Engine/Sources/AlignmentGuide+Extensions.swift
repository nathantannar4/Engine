//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View {

    /// Sets the view's vertical alignment guide `g` to the position of another
    /// vertical alignment guide, `value`, of the same view.
    @inlinable
    public func alignmentGuide(
        _ g: VerticalAlignment,
        value: VerticalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }

    /// Sets the view's horizontal alignment guide `g` to the position of another
    /// horizontal alignment guide, `value`, of the same view.
    @inlinable
    public func alignmentGuide(
        _ g: HorizontalAlignment,
        value: HorizontalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }
}

// MARK: - Previews

struct AlignmentGuideExtensions_Previews: PreviewProvider {
    static var previews: some View {
        HStack(alignment: .center) {
            Text("Label")

            Text("Value")
                .alignmentGuide(VerticalAlignment.center, value: .bottom)
        }
    }
}
