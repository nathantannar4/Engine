//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class ValueTests: XCTestCase {

    func testConstant() {
        let lhs = Constant(wrappedValue: { 1 })
        let rhs = Constant(wrappedValue: { 2 })
        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(Constant(wrappedValue: 1), Constant(wrappedValue: 2))
        XCTAssertEqual(lhs.wrappedValue(), 1)
    }

    func testEquatableTuple() throws {
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) else {
            throw XCTSkip("Requires iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0")
        }
        XCTAssertEqual(EquatableTuple(1, "a", true), EquatableTuple(1, "a", true))
        XCTAssertNotEqual(EquatableTuple(1, "a", true), EquatableTuple(1, "b", true))
        XCTAssertNotEqual(EquatableTuple(1, "a", true), EquatableTuple(1, "a", false))
        XCTAssertEqual(EquatableTuple(), EquatableTuple())
    }

    func testStaticCondition() {
        XCTAssert(TrueStaticCondition.value)
        XCTAssertFalse(FalseStaticCondition.value)
        XCTAssertFalse(InvertedStaticCondition<TrueStaticCondition>.value)
        XCTAssert(InvertedStaticCondition<FalseStaticCondition>.value)
        XCTAssert(InvertedStaticCondition<InvertedStaticCondition<TrueStaticCondition>>.value)
        XCTAssert(IsEqual<Int, Int>.value)
        XCTAssertFalse(IsEqual<Int, String>.value)
        XCTAssertFalse(IsEqual<Int, Int?>.value)
    }

    func testUnwrap() throws {
        let values = try XCTUnwrap(unwrap(Optional(1), Optional("a")))
        XCTAssertEqual(values.0, 1)
        XCTAssertEqual(values.1, "a")
        XCTAssertNil(unwrap(Optional(1), Optional<String>.none))
        XCTAssertNil(unwrap(Optional<Int>.none, Optional("a")))
    }

    func testAnyAnimatableData() {
        let a = AnyAnimatableData(CGFloat(1))
        let b = AnyAnimatableData(CGFloat(2))
        XCTAssertEqual(a.value(as: CGFloat.self), 1)
        XCTAssertNil(a.value(as: Double.self))

        XCTAssertEqual((a + b).value(as: CGFloat.self), 3)
        XCTAssertEqual((b - a).value(as: CGFloat.self), 1)
        XCTAssertEqual(a.magnitudeSquared, 1)
        XCTAssertEqual(b.magnitudeSquared, 4)

        var scaled = b
        scaled.scale(by: 2)
        XCTAssertEqual(scaled.value(as: CGFloat.self), 4)

        XCTAssertEqual(a, AnyAnimatableData(CGFloat(1)))
        XCTAssertNotEqual(a, b)
        // Mismatched types are never equal
        XCTAssertNotEqual(a, AnyAnimatableData(Double(1)))
    }

    func testAnyAnimatableDataZero() {
        let value = AnyAnimatableData(CGFloat(2))
        let zero = AnyAnimatableData.zero

        XCTAssertEqual(AnyAnimatableData(CGFloat(0)), zero)
        XCTAssertNotEqual(value, zero)
        XCTAssertEqual((value + zero).value(as: CGFloat.self), 2)
        XCTAssertEqual((value - zero).value(as: CGFloat.self), 2)
        XCTAssertEqual((zero + value).value(as: CGFloat.self), 2)
        XCTAssertEqual((zero - value).value(as: CGFloat.self), -2)
    }
}
