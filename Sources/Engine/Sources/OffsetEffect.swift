//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `GeometryEffect` that can offset the view by a size relative to an anchor.
///
/// In addition to `offset`, the view is translated by its own size in the
/// direction of `anchor` relative to the center. For example, an anchor of
/// `.top` moves the view up by its height, while `.center` applies only the
/// offset.
@frozen
public struct OffsetEffect: GeometryEffect, Animatable {

    /// The amount to offset the view by.
    public var offset: CGSize
    /// The anchor that determines the additional translation relative to the view's size.
    public var anchor: UnitPoint

    public var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(offset.width, offset.height),
                AnimatablePair(anchor.x, anchor.y)
            )
        }
        set {
            offset = CGSize(width: newValue.first.first, height: newValue.first.second)
            anchor = UnitPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    /// Creates an offset effect from horizontal and vertical distances and an anchor.
    @inlinable
    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        anchor: UnitPoint = .center
    ) {
        self.init(offset: CGSize(width: x, height: y), anchor: anchor)
    }

    /// Creates an offset effect from a size and an anchor.
    @inlinable
    public init(
        offset: CGSize,
        anchor: UnitPoint = .center
    ) {
        self.offset = offset
        self.anchor = anchor
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: offset.width + ((anchor.x - 0.5) * 2 * size.width),
                y: offset.height + ((anchor.y - 0.5) * 2 * size.height)
            )
        )
    }
}

extension View {

    /// Offsets this view by the specified horizontal and vertical distances,
    /// relative to an anchor, without affecting layout.
    ///
    /// See ``OffsetEffect`` for how the anchor is applied.
    @inlinable
    public func offset(x: CGFloat = 0, y: CGFloat = 0, anchor: UnitPoint) -> some View {
        modifier(OffsetEffect(x: x, y: y, anchor: anchor).ignoredByLayout())
    }

    /// Offsets this view by the specified size, relative to an anchor,
    /// without affecting layout.
    ///
    /// See ``OffsetEffect`` for how the anchor is applied.
    @inlinable
    public func offset(_ offset: CGSize, anchor: UnitPoint) -> some View {
        modifier(OffsetEffect(offset: offset, anchor: anchor).ignoredByLayout())
    }
}

// MARK: - Previews

struct OffsetEffect_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var offset = CGSize(width: 0, height: 0)

        var body: some View {
            VStack {
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(OffsetEffect(offset: offset, anchor: .top).ignoredByLayout())

                        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 100, height: 100)
                                .offset(offset)
                                .visualEffect { content, proxy in
                                    content
                                        .offset(x: 0, y: -proxy.size.height)
                                }
                        }
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(OffsetEffect(offset: offset).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .offset(offset)
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(OffsetEffect(offset: offset, anchor: .leading).ignoredByLayout())

                        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 100, height: 100)
                                .offset(offset)
                                .visualEffect { content, proxy in
                                    content
                                        .offset(x: -proxy.size.width, y: 0)
                                }
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                HStack {
                    Button {
                        withAnimation(.bouncy) {
                            offset.width += 25
                        }
                    } label: {
                        Text("Translate X")
                    }

                    Button {
                        withAnimation(.bouncy) {
                            offset.height += 25
                        }
                    } label: {
                        Text("Translate Y")
                    }

                    Button {
                        withAnimation(.bouncy) {
                            offset = .zero
                        }
                    } label: {
                        Text("Reset")
                    }
                }
            }
        }
    }
}
