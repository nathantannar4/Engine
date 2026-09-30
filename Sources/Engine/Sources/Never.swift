//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View where Body == Never {
    /// Traps with a fatal error indicating that `body` should not be called
    /// on a primitive view.
    @_transparent
    public func bodyError() -> Never {
        fatalError("body() should not be called on \(String(describing: Self.self))")
    }
}

extension ViewModifier where Body == Never {
    /// Traps with a fatal error indicating that `body(content:)` should not be
    /// called on a primitive view modifier.
    @_transparent
    public func bodyError() -> Never {
        fatalError("body(content:) should not be called on \(String(describing: Self.self))")
    }
}
