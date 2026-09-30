//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class GeometryTests: XCTestCase {

    func testAngleDelta() {
        let start = Angle.degrees(90)
        XCTAssertEqual(start.delta(endAngle: .degrees(180), clockwise: false).degrees, 90)
        XCTAssertEqual(start.delta(endAngle: .degrees(180), clockwise: true).degrees, -270)
        XCTAssertEqual(start.delta(endAngle: .degrees(0), clockwise: true).degrees, -90)
        XCTAssertEqual(start.delta(endAngle: .degrees(0), clockwise: false).degrees, 270)
        XCTAssertEqual(start.delta(endAngle: .degrees(90), clockwise: true).degrees, 0)
        XCTAssertEqual(start.delta(endAngle: .degrees(90), clockwise: false).degrees, 0)
    }

    func testCGFloatRounded() {
        XCTAssertEqual(CGFloat(1.2).rounded(scale: 2), 1.5)
        XCTAssertEqual(CGFloat(1.5).rounded(scale: 2), 1.5)
        XCTAssertEqual(CGFloat(-1.2).rounded(scale: 2), -1.5)
        XCTAssertEqual(CGFloat(1.01).rounded(scale: 1), 2)
        XCTAssertEqual(CGFloat(1.23456).rounded(decimalPoints: 2), 1.23)
        XCTAssertEqual(CGFloat(1.235).rounded(decimalPoints: 1), 1.2)
        XCTAssertEqual(CGFloat(1.5).rounded(decimalPoints: 0), 2)
    }

    func testEdgeInsets() {
        let insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        XCTAssertEqual(insets.horizontal, 6)
        XCTAssertEqual(insets.vertical, 4)
        XCTAssertEqual(EdgeInsets.zero, EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        XCTAssertEqual(EdgeInsets.horizontal(5), EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        XCTAssertEqual(EdgeInsets.vertical(5), EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        XCTAssertEqual(EdgeInsets.uniform(5), EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))

        let directional = insets.toNSDirectionalEdgeInsets()
        XCTAssertEqual(directional.top, 1)
        XCTAssertEqual(directional.leading, 2)
        XCTAssertEqual(directional.bottom, 3)
        XCTAssertEqual(directional.trailing, 4)

        let ltr = insets.toPlatformValue(layoutDirection: .leftToRight)
        XCTAssertEqual(ltr.top, 1)
        XCTAssertEqual(ltr.left, 2)
        XCTAssertEqual(ltr.bottom, 3)
        XCTAssertEqual(ltr.right, 4)

        let rtl = insets.toPlatformValue(layoutDirection: .rightToLeft)
        XCTAssertEqual(rtl.top, 1)
        XCTAssertEqual(rtl.left, 4)
        XCTAssertEqual(rtl.bottom, 3)
        XCTAssertEqual(rtl.right, 2)
    }

    func testUnitPoint() {
        let size = CGSize(width: 100, height: 50)
        XCTAssertEqual(UnitPoint.topLeading.point(in: size), .zero)
        XCTAssertEqual(UnitPoint.center.point(in: size), CGPoint(x: 50, y: 25))
        XCTAssertEqual(UnitPoint.bottomTrailing.point(in: size), CGPoint(x: 100, y: 50))
        XCTAssertEqual(UnitPoint.center.point(in: size, offset: CGPoint(x: 10, y: 20)), CGPoint(x: 60, y: 45))

        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        XCTAssertEqual(UnitPoint.topLeading.point(in: rect), CGPoint(x: 10, y: 20))
        XCTAssertEqual(UnitPoint.bottomTrailing.point(in: rect), CGPoint(x: 110, y: 70))
    }

    func testAnchoredPoint() {
        let size = CGSize(width: 100, height: 50)
        XCTAssertEqual(AnchoredPoint(anchor: .center).point(in: size), CGPoint(x: 50, y: 25))
        XCTAssertEqual(AnchoredPoint(anchor: .trailing, offset: CGPoint(x: -10, y: 5)).point(in: size), CGPoint(x: 90, y: 30))

        var point = AnchoredPoint(anchor: .topLeading)
        point.animatableData = AnchoredPoint(anchor: .bottom, offset: CGPoint(x: 1, y: 2)).animatableData
        XCTAssertEqual(point, AnchoredPoint(anchor: .bottom, offset: CGPoint(x: 1, y: 2)))
    }

    func testProposedSize() {
        XCTAssertEqual(ProposedSize(size: CGSize(width: 10, height: 20)), ProposedSize(width: 10, height: 20))
        XCTAssertEqual(ProposedSize(size: CGSize(width: -1, height: 20)), ProposedSize(width: nil, height: 20))
        XCTAssertEqual(ProposedSize(size: CGSize(width: 10, height: -1)), ProposedSize(width: 10, height: nil))

        XCTAssertEqual(ProposedSize.unspecified.replacingUnspecifiedDimensions(), CGSize(width: 10, height: 10))
        XCTAssertEqual(ProposedSize(width: 5, height: nil).replacingUnspecifiedDimensions(by: CGSize(width: 1, height: 2)), CGSize(width: 5, height: 2))
        XCTAssertEqual(ProposedSize.infinity.replacingUnspecifiedDimensions(), CGSize(width: CGFloat.infinity, height: .infinity))

        for size in [ProposedSize.unspecified, .infinity, ProposedSize(width: 10, height: nil), ProposedSize(width: nil, height: 20)] {
            XCTAssertEqual(ProposedSize(size.toSwiftUI()), size)
        }

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            XCTAssertEqual(ProposedSize(ProposedViewSize(width: 10, height: nil)), ProposedSize(width: 10, height: nil))
            XCTAssertEqual(ProposedSize(ProposedViewSize.unspecified), .unspecified)
            XCTAssertEqual(ProposedSize(ProposedViewSize.infinity), .infinity)
        }
    }

    func testInsetShape() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        XCTAssertEqual(
            Rectangle().inset(by: insets).path(in: rect).boundingRect,
            CGRect(x: 2, y: 1, width: 94, height: 46)
        )
        XCTAssertEqual(
            Rectangle().inset(dx: 10, dy: 5).path(in: rect).boundingRect,
            CGRect(x: 10, y: 5, width: 80, height: 40)
        )
        XCTAssertEqual(
            InsetShape(shape: Rectangle(), by: 10).path(in: rect).boundingRect,
            CGRect(x: 10, y: 10, width: 80, height: 30)
        )
        // Insets larger than the rect clamp to an empty size
        XCTAssertEqual(
            Rectangle().inset(dx: 60, dy: 0).path(in: rect).boundingRect.width,
            0
        )
        // Chained insets from `InsettableShape` compose
        XCTAssertEqual(
            Rectangle().inset(dx: 10, dy: 5).inset(by: 5).path(in: rect).boundingRect,
            CGRect(x: 15, y: 10, width: 70, height: 30)
        )
    }

    func testEmptyShape() {
        XCTAssert(EmptyShape().path(in: .zero).isEmpty)
        XCTAssertFalse(EmptyShape().path(in: CGRect(x: 0, y: 0, width: 10, height: 10)).isEmpty)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            XCTAssertEqual(EmptyShape().sizeThatFits(.unspecified), .zero)
            XCTAssertEqual(EmptyShape().sizeThatFits(ProposedViewSize(width: 10, height: 10)), .zero)
        }
    }
}
