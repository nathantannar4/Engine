//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct EmptyShape: Shape {

    @inlinable
    public init() { }

    public func path(in rect: CGRect) -> Path {
        return Path()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        return .zero
    }
}
