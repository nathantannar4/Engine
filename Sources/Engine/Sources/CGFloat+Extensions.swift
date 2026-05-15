//
// Copyright (c) Nathan Tannar
//

import Foundation

extension CGFloat {
    func rounded(scale: CGFloat) -> CGFloat {
        (self * scale).rounded(.awayFromZero) / scale
    }

    func rounded(decimalPoints: Int) -> CGFloat {
        let multiplier = pow(10.0, CGFloat(decimalPoints))
        return (self * multiplier).rounded() / multiplier
    }
}
