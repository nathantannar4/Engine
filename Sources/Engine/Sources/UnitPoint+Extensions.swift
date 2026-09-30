//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension UnitPoint {

    /// Returns the point at this unit point within a region of `size`, translated by `offset`.
    @inlinable
    public func point(in size: CGSize, offset: CGPoint = .zero) -> CGPoint {
        CGPoint(x: offset.x + x * size.width, y: offset.y + y * size.height)
    }

    /// Returns the point at this unit point within `rect`.
    @inlinable
    public func point(in rect: CGRect) -> CGPoint {
        point(in: rect.size, offset: rect.origin)
    }
}
