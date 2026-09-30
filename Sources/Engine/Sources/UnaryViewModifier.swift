//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that wraps `Content` in a unary view.
///
/// See Also:
///  - ``UnaryViewAdaptor``
///
@frozen
public struct UnaryViewModifier: ViewModifier {

    /// Creates a modifier that wraps the content in a unary view.
    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        UnaryViewAdaptor {
            content
        }
    }
}
