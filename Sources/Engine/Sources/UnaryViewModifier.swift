//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that wraps `Content` in unary view.
///
/// See Also:
///  - ``UnaryViewAdaptor``
///
@frozen
public struct UnaryViewModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        UnaryViewAdaptor {
            content
        }
    }
}
