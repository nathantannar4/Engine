//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A layout that adapts to the available space by providing the first
/// child layout that fits.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct LayoutThatFits: Layout {

    @usableFromInline
    var axes: Axis.Set

    @usableFromInline
    var layouts: [AnyLayout]

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        var sizeThatFits: CGSize = .zero
        visit(cache: &cache) { stop, cache, layout in
            if stop || layoutFits(layout: layout, proposal: proposal, subviews: subviews, cache: &cache) {
                stop = true
                sizeThatFits = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
            }
        }
        return sizeThatFits
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        visit(cache: &cache) { stop, cache, layout in
            if stop || layoutFits(layout: layout, proposal: proposal, subviews: subviews, cache: &cache) {
                stop = true
                layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
            }
        }
    }

    public func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        var alignment: CGFloat?
        visit(cache: &cache) { stop, cache, layout in
            if stop || layoutFits(layout: layout, proposal: proposal, subviews: subviews, cache: &cache) {
                stop = true
                alignment = layout.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
            }
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
        var alignment: CGFloat?
        visit(cache: &cache) { stop, cache, layout in
            if stop || layoutFits(layout: layout, proposal: proposal, subviews: subviews, cache: &cache) {
                stop = true
                alignment = layout.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
            }
        }
        return alignment
    }

    public struct Cache {
        var caches: [AnyLayout.Cache]
    }

    public func makeCache(
        subviews: Subviews
    ) -> Cache {
        let caches = layouts.map { $0.makeCache(subviews: subviews) }
        return Cache(caches: caches)
    }

    public func updateCache(
        _ cache: inout Cache,
        subviews: Subviews
    ) {
        for index in layouts.indices {
            layouts[index].updateCache(&cache.caches[index], subviews: subviews)
        }
    }

    private func visit(
        cache: inout Cache,
        _ accessor: (inout Bool, inout AnyLayout.Cache, AnyLayout) -> Void
    ) {
        var stop = false
        var index = 0
        while !stop {
            stop = index == layouts.count - 1
            accessor(&stop, &cache.caches[index], layouts[index])
            index += 1
        }
    }

    private func layoutFits(
        layout: AnyLayout,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout AnyLayout.Cache
    ) -> Bool {
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)

        let widthFits = size.width <= (proposal.width ?? .infinity)
        let heightFits = size.height <= (proposal.height ?? .infinity)

        let layoutFits = (widthFits || !axes.contains(.horizontal)) && (heightFits || !axes.contains(.vertical))
        return layoutFits
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LayoutThatFits {
    @inlinable
    public init<
        L1: Layout,
        L2: Layout
    >(
        in axes: Axis.Set = [.horizontal, .vertical],
        _ l1: L1,
        _ l2: L2
    ) {
        self.init(in: axes, [AnyLayout(l1), AnyLayout(l2)])
    }

    @inlinable
    public init<
        L1: Layout,
        L2: Layout,
        L3: Layout
    >(
        in axes: Axis.Set = [.horizontal, .vertical],
        _ l1: L1,
        _ l2: L2,
        _ l3: L3
    ) {
        self.init(in: axes, [AnyLayout(l1), AnyLayout(l2), AnyLayout(l3)])
    }

    @inlinable
    public init<
        L1: Layout,
        L2: Layout,
        L3: Layout,
        L4: Layout
    >(
        in axes: Axis.Set = [.horizontal, .vertical],
        _ l1: L1,
        _ l2: L2,
        _ l3: L3,
        _ l4: L4
    ) {
        self.init(in: axes, [AnyLayout(l1), AnyLayout(l2), AnyLayout(l3), AnyLayout(l4)])
    }

    @inlinable
    public init<
        L1: Layout,
        L2: Layout,
        L3: Layout,
        L4: Layout,
        L5: Layout
    >(
        in axes: Axis.Set = [.horizontal, .vertical],
        _ l1: L1,
        _ l2: L2,
        _ l3: L3,
        _ l4: L4,
        _ l5: L5
    ) {
        self.init(in: axes, [AnyLayout(l1), AnyLayout(l2), AnyLayout(l3), AnyLayout(l4), AnyLayout(l5)])
    }

    @usableFromInline
    init(
        in axes: Axis.Set = [.horizontal, .vertical],
        _ layouts: [AnyLayout]
    ) {
        self.axes = axes
        self.layouts = layouts
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(tvOS, unavailable)
struct LayoutThatFits_Previews: PreviewProvider {
    struct Preview: View {
        @State private var width: CGFloat = 300

        var content: some View {
            Group {
                Text("Layout")
                Text("That")
                Text("Fits")
            }
            .lineLimit(1)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
        }

        var body: some View {
            VStack {
                Slider(value: $width, in: 0...400)

                LayoutThatFits(in: [.horizontal], _HStackLayout(spacing: nil), _VStackLayout(spacing: nil)).callAsFunction {
                    content
                }
                .frame(width: width)
                .background(Color.gray)
                .animation(.default, value: width)

                Spacer()
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}
