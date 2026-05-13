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
public struct UnevenRoundedRectangle: Shape {

    public var topLeadingRadius: CGFloat
    public var bottomLeadingRadius: CGFloat
    public var topTrailingRadius: CGFloat
    public var bottomTrailingRadius: CGFloat
    public var style: RoundedCornerStyle

    @_disfavoredOverload
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
            ).path(in: rect)
        }
        var path = Path()

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
}

// MARK: - Previews

struct UnevenRoundedRectangle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 12, topTrailingRadius: 0)
                .fill(Color.blue)
                .frame(height: 50)

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                SwiftUI.UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 12, topTrailingRadius: 0)
                    .fill(Color.blue)
                    .frame(height: 50)
            }
        }
        .padding()
    }
}
