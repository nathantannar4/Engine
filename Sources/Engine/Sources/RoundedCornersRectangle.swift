//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in UnevenRoundedRectangle")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in UnevenRoundedRectangle")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in UnevenRoundedRectangle")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in UnevenRoundedRectangle")
@available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in UnevenRoundedRectangle")
public struct RoundedCornersRectangle: Shape, InsettableShape {

    public var topLeadingRadius: CGFloat
    public var bottomLeadingRadius: CGFloat
    public var bottomTrailingRadius: CGFloat
    public var topTrailingRadius: CGFloat
    public var inset: CGFloat
    public var style: RoundedCornerStyle

    public typealias AnimatableData = AnimatablePair<AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>, CGFloat>
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(
                    AnimatablePair(topLeadingRadius, bottomLeadingRadius),
                    AnimatablePair(bottomTrailingRadius, topTrailingRadius)
                ),
                inset
            )
        }
        set {
            topLeadingRadius = newValue.first.first.first
            bottomLeadingRadius = newValue.first.first.second
            bottomTrailingRadius = newValue.first.second.first
            topTrailingRadius = newValue.first.second.second
            inset = newValue.second
        }
    }

    @inlinable
    public init(
        topLeadingRadius: CGFloat = 0,
        bottomLeadingRadius: CGFloat = 0,
        bottomTrailingRadius: CGFloat = 0,
        topTrailingRadius: CGFloat = 0,
        style: RoundedCornerStyle = .continuous
    ) {
        self.topLeadingRadius = topLeadingRadius
        self.bottomLeadingRadius = bottomLeadingRadius
        self.bottomTrailingRadius = bottomTrailingRadius
        self.topTrailingRadius = topTrailingRadius
        self.inset = 0
        self.style = style
    }

    public func path(in rect: CGRect) -> Path {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return SwiftUI.UnevenRoundedRectangle(
                topLeadingRadius: topLeadingRadius,
                bottomLeadingRadius: bottomLeadingRadius,
                bottomTrailingRadius: bottomTrailingRadius,
                topTrailingRadius: topTrailingRadius,
                style: style
            ).inset(by: inset).path(in: rect)
        }
        var path = Path()
        let rect = rect.insetBy(dx: inset, dy: inset)
        let topLeadingRadius = max(0, topLeadingRadius - inset)
        let bottomLeadingRadius = max(0, bottomLeadingRadius - inset)
        let bottomTrailingRadius = max(0, bottomTrailingRadius - inset)
        let topTrailingRadius = max(0, topTrailingRadius - inset)
        path.move(to: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
        path.addArc(
            center: CGPoint(
                x: rect.maxX - topTrailingRadius,
                y: rect.minY + topTrailingRadius
            ),
            radius: topTrailingRadius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomTrailingRadius, y: rect.maxY - bottomTrailingRadius),
            radius: bottomTrailingRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY - bottomLeadingRadius),
            radius: bottomLeadingRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius))
        path.addArc(
            center: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY + topLeadingRadius),
            radius: topLeadingRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )

        return path
    }

    public nonisolated func inset(by amount: CGFloat) -> RoundedCornersRectangle {
        var copy = self
        copy.inset += amount
        return copy
    }
}

#if canImport(FoundationModels) // Xcode 26
extension RoundedCornersRectangle: RoundedRectangularShape {

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        return Corners(
            topLeading: .fixed(topLeadingRadius),
            topTrailing: .fixed(topTrailingRadius),
            bottomLeading: .fixed(bottomLeadingRadius),
            bottomTrailing: .fixed(bottomTrailingRadius)
        )
    }
}
#endif

// MARK: - Previews

struct RoundedCornersRectangle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {

        @State var flag = false

        var body: some View {
            let cornerRadius: CGFloat = flag ? 24 : 12
            VStack {
                RoundedCornersRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: 0
                )
                .fill(Color.blue)
                .frame(height: 50)

                RoundedCornersRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: 0
                )
                .inset(by: 10)
                .fill(Color.blue)
                .frame(height: 50)

                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: 0
                    )
                    .fill(Color.blue)
                    .frame(height: 50)

                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: 0
                    )
                    .inset(by: 10)
                    .fill(Color.blue)
                    .frame(height: 50)
                }

                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }
            }
            .padding()
        }
    }
}
