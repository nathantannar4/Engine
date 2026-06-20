//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct ProposedSize: Equatable, Sendable {
    public var width: CGFloat?
    public var height: CGFloat?

    @inlinable
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    @inlinable
    public init(size: CGSize) {
        self.width = size.width >= 0 ? size.width : nil
        self.height = size.height >= 0 ? size.height : nil
    }

    public init(_ proposedSize: _ProposedSize) {
        assert(MemoryLayout<ProposedSize>.size == MemoryLayout<_ProposedSize>.size)
        self = withUnsafePointer(to: proposedSize) {
            $0.withMemoryRebound(to: ProposedSize.self, capacity: 1) { ptr in
                ptr.pointee
            }
        }
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @inlinable
    public init(_ proposedSize: ProposedViewSize) {
        self.init(width: proposedSize.width, height: proposedSize.height)
    }

    @inlinable
    public func replacingUnspecifiedDimensions(by size: CGSize = CGSize(width: 10, height: 10)) -> CGSize {
        return CGSize(width: width ?? size.width, height: height ?? size.height)
    }

    public func toSwiftUI() -> _ProposedSize {
        assert(MemoryLayout<ProposedSize>.size == MemoryLayout<_ProposedSize>.size)
        return withUnsafePointer(to: self) {
            $0.withMemoryRebound(to: _ProposedSize.self, capacity: 1) { ptr in
                ptr.pointee
            }
        }
    }

    public static let unspecified = ProposedSize(width: nil, height: nil)

    public static let infinity = ProposedSize(width: .infinity, height: .infinity)
}
