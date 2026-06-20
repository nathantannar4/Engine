//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension UnitPoint {

    @inlinable
    public func point(in size: CGSize, offset: CGPoint = .zero) -> CGPoint {
        CGPoint(x: offset.x + x * size.width, y: offset.y + y * size.height)
    }

    @inlinable
    public func point(in rect: CGRect) -> CGPoint {
        point(in: rect.size, offset: rect.origin)
    }
}
