//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension _ViewModifier_Content {
    @_transparent
    public init() {
        precondition(MemoryLayout<Self>.size == 0)
        let content = unsafeBitCast(Void(), to: Self.self)
        self = content
    }
}
