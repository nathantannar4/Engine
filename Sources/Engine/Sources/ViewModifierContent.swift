//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension _ViewModifier_Content {
    /// Creates the content placeholder of a `ViewModifier`.
    ///
    /// This is possible since `_ViewModifier_Content` is a zero-sized type.
    @_transparent
    public init() {
        precondition(MemoryLayout<Self>.size == 0)
        let content = unsafeBitCast(Void(), to: Self.self)
        self = content
    }
}
