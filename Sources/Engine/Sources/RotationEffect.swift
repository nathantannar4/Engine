//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``GeometryEffect`` that can rotate the view by an angle relative to an anchor
@frozen
public struct RotationEffect: GeometryEffect, Animatable {

    public var angle: Angle
    public var anchor: UnitPoint

    public var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                angle.radians,
                AnimatablePair(anchor.x, anchor.y)
            )
        }
        set {
            angle = Angle(radians: newValue.first)
            anchor = UnitPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    @inlinable
    public init(
        angle: Angle,
        anchor: UnitPoint = .center
    ) {
        self.angle = angle
        self.anchor = anchor
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        let sin = sin(angle.radians)
        let cos = cos(angle.radians)
        let x = anchor.x * size.width
        let y = anchor.y * size.height
        return ProjectionTransform(
            CGAffineTransform(
                cos,
                sin,
                -sin,
                cos,
                x - x * cos + y * sin,
                y - x * sin - y * cos
            )
        )
    }
}

// MARK: - Previews

struct RotationEffect_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var angle: CGFloat = 120

        var body: some View {
            VStack {
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(RotationEffect(angle: Angle(degrees: angle), anchor: .top).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .rotationEffect(Angle(degrees: angle), anchor: .top)
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(RotationEffect(angle: Angle(degrees: angle)).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .rotationEffect(Angle(degrees: angle))
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .modifier(RotationEffect(angle: Angle(degrees: angle), anchor: .leading).ignoredByLayout())

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100, height: 100)
                            .rotationEffect(Angle(degrees: angle), anchor: .leading)
                    }
                }
                .frame(maxHeight: .infinity)

                Button {
                    withAnimation(.bouncy) {
                        angle += 60
                    }
                } label: {
                    Text("Rotate")
                }
            }
        }
    }
}
