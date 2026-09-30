//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class ShapeTests: XCTestCase {

    let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

    func testRoundedCornersRectangle() {
        let shape = RoundedCornersRectangle(
            topLeadingRadius: 1,
            bottomLeadingRadius: 2,
            bottomTrailingRadius: 3,
            topTrailingRadius: 4
        )
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect)
        XCTAssertEqual(shape.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 5, dy: 5))
        // Insets accumulate
        XCTAssertEqual(shape.inset(by: 5).inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 10, dy: 10))

        var copy = RoundedCornersRectangle()
        copy.animatableData = shape.inset(by: 5).animatableData
        XCTAssertEqual(copy.topLeadingRadius, 1)
        XCTAssertEqual(copy.bottomLeadingRadius, 2)
        XCTAssertEqual(copy.bottomTrailingRadius, 3)
        XCTAssertEqual(copy.topTrailingRadius, 4)
        XCTAssertEqual(copy.inset, 5)
    }

    func testCapsuleRoundedRectangle() {
        let shape = CapsuleRoundedRectangle(maxCornerRadius: 10)
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect)
        XCTAssertEqual(shape.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 5, dy: 5))
        XCTAssertEqual(CapsuleRoundedRectangle(maxCornerRadius: nil).path(in: rect).boundingRect, rect)
        XCTAssertEqual(CapsuleRoundedRectangle(maxCornerRadius: 10, style: .circular).style, .rounded(.circular))
        XCTAssertEqual(CapsuleRoundedRectangle(maxCornerRadius: 10).style, .automatic)

        XCTAssertEqual(shape.animatableData.first, 10)
        XCTAssertEqual(shape.animatableData.second, 0)
        XCTAssertEqual(shape.inset(by: 5).animatableData.second, 5)
        XCTAssertEqual(CapsuleRoundedRectangle(maxCornerRadius: nil).animatableData.first, 0)

        var copy = CapsuleRoundedRectangle(maxCornerRadius: nil)
        copy.animatableData = AnimatablePair(20, 2)
        XCTAssertEqual(copy.maxCornerRadius, 20)
        XCTAssertEqual(copy.animatableData.second, 2)
    }

    func testConditionalShape() {
        let trueShape = ConditionalShape<Rectangle, InsetShape<Rectangle>>(Rectangle())
        let falseShape = ConditionalShape<Rectangle, InsetShape<Rectangle>>(Rectangle().inset(dx: 10, dy: 10))
        XCTAssertEqual(trueShape.path(in: rect).boundingRect, rect)
        XCTAssertEqual(falseShape.path(in: rect).boundingRect, rect.insetBy(dx: 10, dy: 10))

        XCTAssertEqual(trueShape.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 5, dy: 5))
        XCTAssertEqual(falseShape.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 15, dy: 15))

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            XCTAssertEqual(ConditionalShape<Rectangle, Circle>.role, .fill)
            XCTAssertEqual(ConditionalShape<Line, Line>.role, .stroke)
            XCTAssertEqual(ConditionalShape<Line, Rectangle>.role, .fill)
        }
    }

    func testConditionalShapeAnimatableData() {
        var shape = ConditionalShape<InsetShape<Rectangle>, Circle>(Rectangle().inset(dx: 10, dy: 10))
        let target = Rectangle().inset(dx: 20, dy: 20)
        shape.animatableData = AnyAnimatableData(target.animatableData)
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect.insetBy(dx: 20, dy: 20))

        // Mismatched animatable data is ignored
        shape.animatableData = AnyAnimatableData(CGFloat(1))
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect.insetBy(dx: 20, dy: 20))
    }

    func testOptionalShape() {
        let some = OptionalShape(Rectangle())
        let none = OptionalShape<Rectangle>(nil)
        XCTAssertEqual(some.path(in: rect).boundingRect, rect)
        XCTAssertEqual(none.path(in: rect), EmptyShape().path(in: rect))
        XCTAssertNil(none.inset(by: 5).shape)
        XCTAssertEqual(some.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 5, dy: 5))
        XCTAssertNotNil(none.animatableData.value(as: EmptyAnimatableData.self))

        var animated = OptionalShape(Rectangle().inset(dx: 1, dy: 1))
        animated.animatableData = AnyAnimatableData(Rectangle().inset(dx: 10, dy: 10).animatableData)
        XCTAssertEqual(animated.shape?.insets, EdgeInsets.uniform(10))

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            XCTAssertEqual(none.sizeThatFits(ProposedViewSize(width: 10, height: 10)), .zero)
        }
    }

    @available(iOS, deprecated: 16.0)
    @available(macOS, deprecated: 13.0)
    @available(tvOS, deprecated: 16.0)
    @available(watchOS, deprecated: 9.0)
    @available(visionOS, deprecated: 1.1)
    func testAnyShape() {
        let shape = Engine.AnyShape(shape: Rectangle().inset(dx: 10, dy: 10))
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect.insetBy(dx: 10, dy: 10))
        XCTAssertEqual(shape.inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 15, dy: 15))

        // Non-insettable shapes fall back to `InsetShape`
        struct CustomShape: Shape {
            nonisolated func path(in rect: CGRect) -> Path {
                Path(rect)
            }
        }
        XCTAssertEqual(Engine.AnyShape(shape: CustomShape()).inset(by: 5).path(in: rect).boundingRect, rect.insetBy(dx: 5, dy: 5))

        // Mutating animatable data does not affect copies
        var copy = shape
        copy.animatableData = AnyAnimatableData(Rectangle().inset(dx: 20, dy: 20).animatableData)
        XCTAssertEqual(copy.path(in: rect).boundingRect, rect.insetBy(dx: 20, dy: 20))
        XCTAssertEqual(shape.path(in: rect).boundingRect, rect.insetBy(dx: 10, dy: 10))
    }

    func testShapeBuilder() {
        func build<S: Shape>(@ShapeBuilder _ shape: () -> S) -> S {
            shape()
        }

        let empty = build { }
        XCTAssert(type(of: empty) == EmptyShape.self)

        let single = build { Rectangle() }
        XCTAssert(type(of: single) == Rectangle.self)

        let flag = true
        let conditional = build {
            if flag {
                Rectangle()
            } else {
                Circle()
            }
        }
        XCTAssert(type(of: conditional) == ConditionalShape<Rectangle, Circle>.self)
        if case .trueContent = conditional.storage { } else {
            XCTFail("Expected true content")
        }

        let optional = build {
            if !flag {
                Rectangle()
            }
        }
        XCTAssert(type(of: optional) == OptionalShape<Rectangle>.self)
        XCTAssertNil(optional.shape)
    }

    func testLine() {
        let line = Line(startPoint: .leading, endPoint: .trailing, strokeStyle: StrokeStyle(lineWidth: 2))
        let bounds = line.path(in: rect).boundingRect
        XCTAssertEqual(bounds.minX, 0, accuracy: 1)
        XCTAssertEqual(bounds.maxX, 100, accuracy: 1)
        XCTAssertEqual(bounds.height, 2, accuracy: 0.01)
        XCTAssertEqual(bounds.midY, 25, accuracy: 0.01)

        let polyline = Line(
            startPoint: .topLeading,
            endPoint: .topTrailing,
            segments: [.linear(point: .bottom)]
        )
        let polylineBounds = polyline.path(in: rect).boundingRect
        XCTAssertEqual(polylineBounds.maxY, 50, accuracy: 1)

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            XCTAssertEqual(Line.role, .stroke)
        }
    }

    func testLineAnimatableData() {
        var line = Line(startPoint: .leading, endPoint: .trailing)
        let target = Line(
            startPoint: AnchoredPoint(anchor: .top, offset: CGPoint(x: 1, y: 2)),
            endPoint: AnchoredPoint(anchor: .bottom),
            strokeStyle: StrokeStyle(lineWidth: 4)
        )
        line.animatableData = target.animatableData
        XCTAssertEqual(line.startPoint, target.startPoint)
        XCTAssertEqual(line.endPoint, target.endPoint)
        XCTAssertEqual(line.strokeStyle.lineWidth, 4)
    }

    func testLineSegmentSet() {
        let lhs: Line.Segment.Set = [
            .linear(point: UnitPoint(x: 0.25, y: 0.5)),
            .arc(center: .center, radius: 10, startAngle: .degrees(0), delta: .degrees(90)),
        ]
        let rhs: Line.Segment.Set = [
            .linear(point: UnitPoint(x: 0.25, y: 0.5)),
        ]

        let sum = lhs + rhs
        XCTAssertEqual(sum.elements.count, 2)
        XCTAssertEqual(sum.elements[0], .linear(point: UnitPoint(x: 0.5, y: 1)))
        XCTAssertEqual(sum.elements[1], lhs.elements[1])

        let difference = lhs - rhs
        XCTAssertEqual(difference.elements[0], .linear(point: UnitPoint(x: 0, y: 0)))
        XCTAssertEqual(lhs - lhs, [
            .linear(point: UnitPoint(x: 0, y: 0)),
            .arc(center: .zero, radius: 0, startAngle: .zero, delta: .zero),
        ])

        var scaled = lhs
        scaled.scale(by: 2)
        XCTAssertEqual(scaled.elements[0], .linear(point: UnitPoint(x: 0.5, y: 1)))
        XCTAssertEqual(
            scaled.elements[1],
            .arc(center: UnitPoint(x: 1, y: 1), radius: 20, startAngle: .degrees(0), delta: .degrees(180))
        )

        XCTAssertEqual(Line.Segment.Set.zero.magnitudeSquared, 0)
        XCTAssertEqual(rhs.magnitudeSquared, rhs.elements[0].animatableData.magnitudeSquared)
        XCTAssertEqual(Line.Segment.Set.zero + lhs, lhs)
    }

    func testLineSegmentAnimatableData() {
        var segment = Line.Segment.tangentArc(tangent1End: .top, tangent2End: .bottom, radius: 5)
        segment.animatableData = Line.Segment.tangentArc(tangent1End: .leading, tangent2End: .trailing, radius: 10).animatableData
        XCTAssertEqual(segment, .tangentArc(tangent1End: .leading, tangent2End: .trailing, radius: 10))

        // Segments without a radius ignore it
        var linear = Line.Segment.linear(point: .top)
        var data = linear.animatableData
        data.second.first = 100
        linear.animatableData = data
        XCTAssertEqual(linear, .linear(point: .top))
    }
}
