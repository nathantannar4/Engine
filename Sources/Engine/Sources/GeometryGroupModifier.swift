//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that applies the ``geometryGroup()`` modifier when available
@frozen
public struct GeometryGroupModifier: VersionedViewModifier {

    public init() { }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .geometryGroup()
    }
}
