//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A wrapper for `@ViewBuilder`
@frozen
public struct ViewAdapter<Content: View>: View {

    @usableFromInline
    var content: Content

    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
    }
}
