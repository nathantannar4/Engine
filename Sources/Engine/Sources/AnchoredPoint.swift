//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct AnchoredPoint: Hashable, Sendable, Animatable {

    public var anchor: UnitPoint
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

    @inlinable
    public init(
        anchor: UnitPoint,
        offset: CGPoint = .zero
    ) {
        self.anchor = anchor
        self.offset = offset
    }

    @inlinable
    public func point(in size: CGSize) -> CGPoint {
        anchor.point(in: size, offset: offset)
    }
}
