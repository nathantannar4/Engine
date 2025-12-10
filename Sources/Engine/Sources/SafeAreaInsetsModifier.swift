//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that adds additional safe area padding
/// to the edges of a view.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct SafeAreaInsetsModifier: VersionedViewModifier {
    public var edgeInsets: EdgeInsets

    @inlinable
    public init(_ edgeInsets: EdgeInsets) {
        self.edgeInsets = edgeInsets
    }

    @inlinable
    public init(_ length: CGFloat = 16) {
        self.init(EdgeInsets(top: length, leading: length, bottom: length, trailing: length))
    }

    @inlinable
    public init(_ edges: Edge.Set, _ length: CGFloat = 16) {
        let edgeInsets = EdgeInsets(
            top: edges.contains(.top) ? length : 0,
            leading: edges.contains(.leading) ? length : 0,
            bottom: edges.contains(.bottom) ? length : 0,
            trailing: edges.contains(.trailing) ? length : 0
        )
        self.init(edgeInsets)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            ._safeAreaInsets(edgeInsets)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func v2Body(content: Content) -> some View {
        content
            ._safeAreaInsets(edgeInsets)
    }
}

@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Please use the built in safeAreaPadding modifier")
@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Please use the built in safeAreaPadding modifier")
@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Please use the built in safeAreaPadding modifier")
@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Please use the built in safeAreaPadding modifier")
@available(visionOS, unavailable)
extension View {

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    public func safeAreaInsets(_ edgeInsets: EdgeInsets) -> some View {
        modifier(SafeAreaInsetsModifier(edgeInsets))
    }

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    public func safeAreaInsets(_ length: CGFloat = 16) -> some View {
        modifier(SafeAreaInsetsModifier(length))
    }

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    public func safeAreaInsets(_ edges: Edge.Set, _ length: CGFloat = 16) -> some View {
        modifier(SafeAreaInsetsModifier(edges, length))
    }
}
