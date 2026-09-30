//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A proposal for the size of a view, where a `nil` dimension is unspecified.
///
/// This mirrors `ProposedViewSize`, and is layout compatible with
/// SwiftUI's `_ProposedSize`.
@frozen
public struct ProposedSize: Equatable, Sendable {
    /// The proposed horizontal size, or `nil` if unspecified.
    public var width: CGFloat?
    /// The proposed vertical size, or `nil` if unspecified.
    public var height: CGFloat?

    /// Creates a proposed size from the given width and height.
    @inlinable
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    /// Creates a proposed size from a size, treating negative dimensions as unspecified.
    @inlinable
    public init(size: CGSize) {
        self.width = size.width >= 0 ? size.width : nil
        self.height = size.height >= 0 ? size.height : nil
    }

    /// Creates a proposed size from SwiftUI's `_ProposedSize`.
    public init(_ proposedSize: _ProposedSize) {
        assert(MemoryLayout<ProposedSize>.size == MemoryLayout<_ProposedSize>.size)
        self = withUnsafePointer(to: proposedSize) {
            $0.withMemoryRebound(to: ProposedSize.self, capacity: 1) { ptr in
                ptr.pointee
            }
        }
    }

    /// Creates a proposed size from a `ProposedViewSize`.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @inlinable
    public init(_ proposedSize: ProposedViewSize) {
        self.init(width: proposedSize.width, height: proposedSize.height)
    }

    /// Creates a new proposal that replaces unspecified dimensions in this
    /// proposal with the corresponding dimension of the specified size.
    @inlinable
    public func replacingUnspecifiedDimensions(by size: CGSize = CGSize(width: 10, height: 10)) -> CGSize {
        return CGSize(width: width ?? size.width, height: height ?? size.height)
    }

    /// Converts the proposed size to SwiftUI's `_ProposedSize`.
    public func toSwiftUI() -> _ProposedSize {
        assert(MemoryLayout<ProposedSize>.size == MemoryLayout<_ProposedSize>.size)
        return withUnsafePointer(to: self) {
            $0.withMemoryRebound(to: _ProposedSize.self, capacity: 1) { ptr in
                ptr.pointee
            }
        }
    }

    /// A size proposal that contains `nil` in both dimensions.
    public static let unspecified = ProposedSize(width: nil, height: nil)

    /// A size proposal that contains infinity in both dimensions.
    public static let infinity = ProposedSize(width: .infinity, height: .infinity)
}
