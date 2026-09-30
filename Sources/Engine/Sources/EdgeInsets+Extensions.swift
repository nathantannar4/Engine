//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EdgeInsets {

    /// The sum of the leading and trailing insets.
    @inlinable
    public var horizontal: CGFloat {
        leading + trailing
    }

    /// The sum of the top and bottom insets.
    @inlinable
    public var vertical: CGFloat {
        top + bottom
    }

    /// Edge insets with all insets set to zero.
    public static let zero = EdgeInsets()

    /// Returns edge insets with the leading and trailing insets set to `inset`.
    @inlinable
    public static func horizontal(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
    }

    /// Returns edge insets with the top and bottom insets set to `inset`.
    @inlinable
    public static func vertical(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0)
    }

    /// Returns edge insets with all insets set to `inset`.
    @inlinable
    public static func uniform(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    }

    /// Transforms SwiftUI `EdgeInsets` to a `NSDirectionalEdgeInsets`
    public func toNSDirectionalEdgeInsets() -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `EdgeInsets` to a `UIEdgeInsets`
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func toUIEdgeInsets(layoutDirection: LayoutDirection) -> UIEdgeInsets {
        toPlatformValue(layoutDirection: layoutDirection)
    }
    #endif

    #if os(macOS)
    /// Transforms SwiftUI `EdgeInsets` to a `NSEdgeInsets`
    @available(macOS 11.0, *)
    public func toNSEdgeInsets(layoutDirection: LayoutDirection) -> NSEdgeInsets {
        toPlatformValue(layoutDirection: layoutDirection)
    }
    #endif

    #if os(macOS)
    /// The platform edge insets type, `NSEdgeInsets`.
    public typealias PlatformRepresentable = NSEdgeInsets
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// The platform edge insets type, `UIEdgeInsets`.
    public typealias PlatformRepresentable = UIEdgeInsets
    #endif
    /// Transforms SwiftUI `EdgeInsets` to the platform edge insets type, mapping the
    /// leading and trailing insets to left and right for the `layoutDirection`
    public func toPlatformValue(layoutDirection: LayoutDirection) -> PlatformRepresentable {
        let left = layoutDirection == .leftToRight ? leading : trailing
        let right = layoutDirection == .leftToRight ? trailing : leading
        return PlatformRepresentable(
            top: top,
            left: left,
            bottom: bottom,
            right: right
        )
    }
}
