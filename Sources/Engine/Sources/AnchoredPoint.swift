//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A point defined by a unit anchor within a size, plus an absolute offset.
@frozen
public struct AnchoredPoint: Hashable, Sendable, Animatable {

    /// The unit point within a size.
    public var anchor: UnitPoint
    /// The offset, in points, added to the anchored point.
    public var offset: CGPoint

    @inlinable
    public var animatableData: AnimatablePair<UnitPoint.AnimatableData, CGPoint.AnimatableData> {
        get {
            AnimatablePair(
                anchor.animatableData,
                offset.animatableData
            )
        }
        set {
            anchor.animatableData = newValue.first
            offset.animatableData = newValue.second
        }
    }

    /// Creates an anchored point from a unit anchor and an offset.
    @inlinable
    public init(
        anchor: UnitPoint,
        offset: CGPoint = .zero
    ) {
        self.anchor = anchor
        self.offset = offset
    }

    /// Returns the point within `size` at ``anchor``, offset by ``offset``.
    @inlinable
    public func point(in size: CGSize) -> CGPoint {
        anchor.point(in: size, offset: offset)
    }
}
