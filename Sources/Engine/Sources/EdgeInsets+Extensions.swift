//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EdgeInsets {

    public var horizontal: CGFloat {
        leading + trailing
    }

    public var vertical: CGFloat {
        top + bottom
    }

    public static let zero = EdgeInsets()

    public static func horizontal(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
    }

    public static func vertical(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0)
    }

    public static func uniform(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
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
    typealias PlatformRepresentable = NSEdgeInsets
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIEdgeInsets
    #endif
    private func toPlatformValue(layoutDirection: LayoutDirection) -> PlatformRepresentable {
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
