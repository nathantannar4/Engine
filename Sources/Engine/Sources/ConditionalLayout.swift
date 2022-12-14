//
// Copyright (c) Nathan Tannar
//

import SwiftUI

import EngineCore

/// A layout that is dynamically either `TrueLayout` or `FalseLayout`.
///
/// A ``ConditionalLayout`` can be more performant than relying on `AnyLayout`
/// since it does not use type-erasure. Additionally, the `Cache` of each `Layout` is
/// stored separately as opposed to being invalidated when the dynamic condition changes.
///
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct ConditionalLayout<
    TrueLayout: Layout,
    FalseLayout: Layout
>: Layout {
    @frozen
    @usableFromInline
    enum Storage {
        case trueLayout(TrueLayout)
        case falseLayout(FalseLayout)
    }

    @usableFromInline
    var storage: Storage

    @inlinable
    public init(_ trueLayout: TrueLayout) {
        self.storage = .trueLayout(trueLayout)
    }

    @inlinable
    public init(_ falseLayout: FalseLayout) {
        self.storage = .falseLayout(falseLayout)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let size: CGSize
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            size = l.sizeThatFits(proposal: proposal, subviews: subviews, cache: &c)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            size = l.sizeThatFits(proposal: proposal, subviews: subviews, cache: &c)
            cache = .falseCache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
        return size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            l.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            l.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .falseCache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
    }

    public func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        let alignment: CGFloat?
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .falseCache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
        return alignment
    }

    public func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        let alignment: CGFloat?
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = .falseCache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
        return alignment
    }

    public func spacing(
        subviews: Subviews,
        cache: inout Cache
    ) -> ViewSpacing {
        let spacing: ViewSpacing
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            spacing = l.spacing(subviews: subviews, cache: &c)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            spacing = l.spacing(subviews: subviews, cache: &c)
            cache = .falseCache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
        return spacing
    }

    @frozen
    public struct Cache {
        @usableFromInline
        enum Value {
            case trueCache(TrueLayout.Cache)
            case falseCache(FalseLayout.Cache)
        }

        @usableFromInline
        var value: Value

        @usableFromInline
        var inverseValue: Value?

        static func trueCache(_ cache: TrueLayout.Cache) -> Cache {
            .init(value: .trueCache(cache))
        }

        static func falseCache(_ cache: FalseLayout.Cache) -> Cache {
            .init(value: .falseCache(cache))
        }
    }

    public func makeCache(subviews: Subviews) -> Cache {
        switch storage {
        case .trueLayout(let layout):
            return .trueCache(layout.makeCache(subviews: subviews))
        case .falseLayout(let layout):
            return .falseCache(layout.makeCache(subviews: subviews))
        }
    }

    public func updateCache(
        _ cache: inout Cache,
        subviews: Subviews
    ) {
        switch (storage, cache.value) {
        case (.trueLayout(let l), .trueCache(var c)):
            l.updateCache(&c, subviews: subviews)
            cache = .trueCache(c)
        case (.falseLayout(let l), .falseCache(var c)):
            l.updateCache(&c, subviews: subviews)
            cache = .falseCache(c)
        case (.trueLayout, .falseCache), (.falseLayout, .trueCache):
            let oldValue = cache.value
            cache = makeCache(subviews: subviews)
            cache.inverseValue = oldValue
        }
    }

    public static var layoutProperties: LayoutProperties {
        TrueLayout.layoutProperties.combined(with: FalseLayout.layoutProperties)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LayoutProperties {
    private struct _LayoutProperties {
        var stackOrientation: Axis?
        var isDefaultEmptyLayout: Bool
        var isIdentityUnaryLayout: Bool
    }

    func combined(with other: LayoutProperties) -> LayoutProperties {
        let other = unsafePartialBitCast(other, to: _LayoutProperties.self)
        var result = self
        withMemoryRebound(&result, to: _LayoutProperties.self) { result in
            if result.stackOrientation != other.stackOrientation {
                result.stackOrientation = nil
            }
            if result.isDefaultEmptyLayout != other.isDefaultEmptyLayout {
                result.isDefaultEmptyLayout = false
            }
            if result.isIdentityUnaryLayout != other.isIdentityUnaryLayout {
                result.isIdentityUnaryLayout = false
            }
        }
        return result
    }
}
