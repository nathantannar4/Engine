//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``GeometryEffect`` that can scale the view by a size relative to an anchor
@frozen
public struct ScaleEffect: GeometryEffect, Animatable {

    public var scale: CGSize
    public var anchor: UnitPoint

    public var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(scale.width, scale.height),
                AnimatablePair(anchor.x, anchor.y)
            )
        }
        set {
            scale = CGSize(width: newValue.first.first, height: newValue.first.second)
            anchor = UnitPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    @inlinable
    public init(
        scale: CGFloat,
        anchor: UnitPoint = .center
    ) {
        self.init(x: scale, y: scale, anchor: anchor)
    }

    @inlinable
    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        anchor: UnitPoint = .center
    ) {
        self.init(scale: CGSize(width: x, height: y), anchor: anchor)
    }

    @inlinable
    public init(
        scale: CGSize,
        anchor: UnitPoint = .center
    ) {
        self.scale = scale
        self.anchor = anchor
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: (1 - scale.width) * anchor.x * size.width,
                y: (1 - scale.height) * anchor.y * size.height
            )
            .scaledBy(x: scale.width, y: scale.height)
        )
    }
}

// MARK: - Previews

struct ScaleEffect_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var scale = CGSize(width: 0.5, height: 0.5)

        var body: some View {
            VStack {
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(ScaleEffect(scale: scale, anchor: .top).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .scaleEffect(scale, anchor: .top)
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(ScaleEffect(scale: scale).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .scaleEffect(scale)
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(ScaleEffect(scale: scale, anchor: .leading).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .scaleEffect(scale, anchor: .leading)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack {
                    Button {
                        withAnimation(.bouncy) {
                            scale.width += 0.25
                        }
                    } label: {
                        Text("Scale X")
                    }

                    Button {
                        withAnimation(.bouncy) {
                            scale.height += 0.25
                        }
                    } label: {
                        Text("Scale Y")
                    }

                    Button {
                        withAnimation(.bouncy) {
                            scale = CGSize(width: 0.5, height: 0.5)
                        }
                    } label: {
                        Text("Reset")
                    }
                }
            }
        }
    }
}
