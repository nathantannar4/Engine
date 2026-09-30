//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that adjusts the alignment guides of a view for an alignment.
///
/// The `anchor` moves each guide from its alignment edge towards the opposite
/// edge, where `0` keeps the guide at the alignment edge, `0.5` moves it to the
/// center and `1` moves it to the opposite edge. The `offset` is then added to
/// the guide.
@frozen
public struct AlignmentGuideOffsetModifier: ViewModifier {

    /// The alignment whose horizontal and vertical guides are adjusted.
    public var alignment: Alignment
    /// The unit position, relative to the alignment edge, to move the guides to.
    public var anchor: UnitPoint
    /// The additional offset, in points, added to the guides.
    public var offset: CGPoint

    /// Creates a modifier that adjusts the alignment guides of `alignment`.
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
    
    /// Adjusts the alignment guides of `alignment` by moving them towards the
    /// opposite edge by `anchor` and then offsetting them by `x` and `y`.
    ///
    /// See ``AlignmentGuideOffsetModifier``.
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

    /// Adjusts the alignment guides of `alignment` by moving them towards the
    /// opposite edge by `anchor` and then offsetting them by `offset`.
    ///
    /// See ``AlignmentGuideOffsetModifier``.
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
