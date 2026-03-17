//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View {

    /// A modifier that transforms a vertical alignment to another
    @inlinable
    public func alignmentGuide(
        _ g: VerticalAlignment,
        value: VerticalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }

    /// A modifier that transforms a horizontal alignment to another
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
