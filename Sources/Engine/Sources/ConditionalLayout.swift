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
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public typealias ConditionalLayout<TrueLayout: Layout, FalseLayout: Layout> = ConditionalContent<TrueLayout, FalseLayout>

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ConditionalLayout: Layout {

    @inlinable
    public init(
        if condition: Bool,
        @LayoutBuilder then: () -> TrueContent,
        @LayoutBuilder otherwise: () -> FalseContent
    ) {
        self.storage = condition ? .trueContent(then()) : .falseContent(otherwise())
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let size: CGSize
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            size = l.sizeThatFits(proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            size = l.sizeThatFits(proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
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
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            l.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            l.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
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
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
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
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            alignment = l.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &c)
            cache = Cache(c)
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
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            spacing = l.spacing(subviews: subviews, cache: &c)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            spacing = l.spacing(subviews: subviews, cache: &c)
            cache = Cache(c)
        default:
            fatalError("Unexpected mismatch between layout and cache")
        }
        return spacing
    }

    @frozen
    public struct Cache {
        public enum Storage {
            case trueCache(TrueContent.Cache)
            case falseCache(FalseContent.Cache)
        }

        public var storage: Storage
        var lastValue: Storage?

        init(_ cache: TrueContent.Cache) {
            self.storage = .trueCache(cache)
        }

        init(_ cache: FalseContent.Cache) {
            self.storage = .falseCache(cache)
        }
    }

    public func makeCache(subviews: Subviews) -> Cache {
        switch storage {
        case .trueContent(let layout):
            return Cache(layout.makeCache(subviews: subviews))
        case .falseContent(let layout):
            return Cache(layout.makeCache(subviews: subviews))
        }
    }

    public func updateCache(
        _ cache: inout Cache,
        subviews: Subviews
    ) {
        switch (storage, cache.storage) {
        case (.trueContent(let l), .trueCache(var c)):
            l.updateCache(&c, subviews: subviews)
            cache = Cache(c)
        case (.falseContent(let l), .falseCache(var c)):
            l.updateCache(&c, subviews: subviews)
            cache = Cache(c)
        case (.trueContent, .falseCache), (.falseContent, .trueCache):
            let oldValue = cache.storage
            if let lastValue = cache.lastValue {
                cache.storage = lastValue
            } else {
                cache = makeCache(subviews: subviews)
            }
            cache.lastValue = oldValue
        }
    }

    public static var layoutProperties: LayoutProperties {
        TrueContent.layoutProperties.combined(with: FalseContent.layoutProperties)
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
        let other = withUnsafePointer(to: other) { ptr in
            ptr.withMemoryRebound(to: _LayoutProperties.self, capacity: 1) { ptr in
                return ptr.pointee
            }
        }
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

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct ConditionalLayout_Previews: PreviewProvider {
    struct Preview: View {
        @State var condition = true

        var body: some View {
            VStack {
                Toggle(
                    isOn: $condition.animation(.default),
                    label: { EmptyView() }
                )
                .labelsHidden()

                ConditionalLayout(if: condition) {
                    VStackLayout()
                } otherwise: {
                    HStackLayout()
                } {
                    content
                }
            }
        }

        @ViewBuilder
        var content: some View {
            Text("Hello")
            Text("World")
        }
    }

    static var previews: some View {
        Preview()
    }
}
