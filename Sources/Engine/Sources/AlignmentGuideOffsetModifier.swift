//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that scales the edge alignment guides by an offset
@frozen
public struct AlignmentGuideOffsetModifier: ViewModifier {

    public var alignment: Alignment
    public var anchor: UnitPoint
    public var offset: CGPoint

    @inlinable
    public init(
        alignment: Alignment,
        anchor: UnitPoint,
        offset: CGPoint
    ) {
        self.alignment = alignment
        self.anchor = anchor
        self.offset = offset
    }

    public func body(content: Content) -> some View {
        content
            .alignmentGuide(alignment.vertical) { d in
                let delta = 2 * (d[VerticalAlignment.center] - d[alignment.vertical])
                return d[alignment.vertical] + delta * anchor.y + offset.y
            }
            .alignmentGuide(alignment.horizontal) { d in
                let delta = 2 * (d[HorizontalAlignment.center] - d[alignment.horizontal])
                return d[alignment.horizontal] + delta * anchor.x + offset.x
            }
    }
}

extension View {
    
    /// A modifier that scales the edge alignment guides by an offset
    @inlinable
    public func alignmentGuideOffset(
        alignment: Alignment,
        anchor: UnitPoint = .zero,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        alignmentGuideOffset(
            alignment: alignment,
            anchor: anchor,
            offset: CGPoint(x: x, y: y)
        )
    }

    /// A modifier that scales the edge alignment guides by an offset
    @inlinable
    public func alignmentGuideOffset(
        alignment: Alignment,
        anchor: UnitPoint,
        offset: CGPoint
    ) -> some View {
        modifier(
            AlignmentGuideOffsetModifier(
                alignment: alignment,
                anchor: anchor,
                offset: offset
            )
        )
    }
}

// MARK: - Previews

struct AlignmentGuideOffsetModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach([VerticalAlignment.top, .center, .bottom]) { _, alignment in
                HStack(alignment: alignment) {
                    Rectangle()
                        .frame(width: 60, height: 60)

                    Rectangle()
                        .frame(width: 80, height: 80)
                        .alignmentGuideOffset(
                            alignment: Alignment(horizontal: .center, vertical: alignment),
                            x: 0,
                            y: -20
                        )

                    Rectangle()
                        .frame(width: 40, height: 40)
                        .alignmentGuideOffset(
                            alignment: Alignment(horizontal: .center, vertical: alignment),
                            x: 0,
                            y: 20
                        )
                }
            }

            HStack(alignment: .bottom) {
                Rectangle()
                    .frame(width: 60, height: 60)

                Rectangle()
                    .frame(width: 80, height: 80)
                    .alignmentGuideOffset(
                        alignment: .bottom,
                        anchor: .bottom,
                        x: 0,
                        y: 0
                    )

                Rectangle()
                    .frame(width: 80, height: 80)
                    .alignmentGuideOffset(
                        alignment: .bottom,
                        anchor: .center,
                        x: 0,
                        y: 0
                    )
            }
        }
    }
}
