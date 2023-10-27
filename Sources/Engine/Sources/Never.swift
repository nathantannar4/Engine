//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View where Body == Never {
    @_transparent
    public func bodyError() -> Never {
        fatalError("body() should not be called on \(String(describing: Self.self))")
    }
}

extension ViewModifier where Body == Never {
    @_transparent
    public func bodyError() -> Never {
        fatalError("body(content:) should not be called on \(String(describing: Self.self))")
    }
}
