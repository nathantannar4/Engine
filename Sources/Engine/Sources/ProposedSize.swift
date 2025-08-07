//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct ProposedSize: Equatable, Sendable {
    public var width: CGFloat?
    public var height: CGFloat?

    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

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
    public init(_ proposedSize: ProposedViewSize) {
        self.init(width: proposedSize.width, height: proposedSize.height)
    }

    @MainActor @preconcurrency
    public func toCoreGraphics() -> CGSize {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return CGSize(width: width ?? UIView.noIntrinsicMetric, height: height ?? UIView.noIntrinsicMetric)
        #elseif os(watchOS)
        return CGSize(width: width ?? -1, height: height ?? -1)
        #elseif os(macOS)
        return CGSize(width: width ?? NSView.noIntrinsicMetric, height: height ?? NSView.noIntrinsicMetric)
        #endif
    }

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
