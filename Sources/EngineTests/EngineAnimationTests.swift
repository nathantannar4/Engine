//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class AnimationTests: XCTestCase {

    func testDefault() throws {
        let resolved = try XCTUnwrap(Animation.default.resolved())
        XCTAssertEqual(resolved.timingCurve, .default)
        XCTAssertEqual(resolved.delay, 0)
        XCTAssertEqual(resolved.speed, 1)
        XCTAssertEqual(resolved.repeatCount, 0)
        XCTAssertFalse(resolved.autoreverses)
        XCTAssertNil(resolved.timingCurve.duration)
        XCTAssertEqual(resolved.duration(defaultDuration: 0.5), 0.5)
    }

    func testModifiers() throws {
        let animation = Animation.linear(duration: 1)
            .delay(0.5)
            .delay(0.25)
            .speed(2)
            .speed(2)
        XCTAssertEqual(animation.delay, 0.75)
        XCTAssertEqual(animation.speed, 4)
        XCTAssertEqual(animation.timingCurveDuration(defaultDuration: 0), 1)
        XCTAssertEqual(animation.duration(defaultDuration: 0), 0.25)
    }

    func testRepeat() {
        let repeating = Animation.linear(duration: 1).repeatCount(3, autoreverses: true)
        XCTAssertEqual(repeating.repeatCount, 3)
        XCTAssertEqual(repeating.autoreverses, true)

        let nonReversing = Animation.linear(duration: 1).repeatCount(2, autoreverses: false)
        XCTAssertEqual(nonReversing.repeatCount, 2)
        XCTAssertEqual(nonReversing.autoreverses, false)

        let forever = Animation.linear(duration: 1).repeatForever(autoreverses: false)
        XCTAssertEqual(forever.repeatCount, .max)
        XCTAssertEqual(forever.autoreverses, false)

        XCTAssertEqual(Animation.linear(duration: 1).repeatCount, 0)
        XCTAssertEqual(Animation.linear(duration: 1).autoreverses, false)
    }

    func testBezierTimingCurve() throws {
        for animation in [Animation.linear(duration: 0.3), .easeIn(duration: 0.3), .easeOut(duration: 0.3), .easeInOut(duration: 0.3)] {
            let timingCurve = try XCTUnwrap(animation.timingCurve)
            guard case .bezier(let bezier) = timingCurve else {
                XCTFail("Expected bezier timing curve for \(animation)")
                continue
            }
            XCTAssertEqual(bezier.duration, 0.3, accuracy: 0.0001)
            XCTAssertEqual(timingCurve.duration ?? 0, 0.3, accuracy: 0.0001)
        }
        XCTAssertNotEqual(Animation.easeIn(duration: 1).timingCurve, Animation.easeOut(duration: 1).timingCurve)
    }

    func testBezierTimingCurveParameters() throws {
        struct TestCase {
            var animation: Animation
            var duration: TimeInterval
            var c0x: Double
            var c0y: Double
            var c1x: Double
            var c1y: Double
        }
        var testCases = [
            TestCase(animation: .linear(duration: 0.4), duration: 0.4, c0x: 0, c0y: 0, c1x: 1, c1y: 1),
            TestCase(animation: .easeIn(duration: 0.5), duration: 0.5, c0x: 0.42, c0y: 0, c1x: 1, c1y: 1),
            TestCase(animation: .easeOut(duration: 0.6), duration: 0.6, c0x: 0, c0y: 0, c1x: 0.58, c1y: 1),
            TestCase(animation: .easeInOut(duration: 0.7), duration: 0.7, c0x: 0.42, c0y: 0, c1x: 0.58, c1y: 1),
            TestCase(animation: .timingCurve(0.1, 0.2, 0.3, 0.9, duration: 0.8), duration: 0.8, c0x: 0.1, c0y: 0.2, c1x: 0.3, c1y: 0.9),
            TestCase(animation: .timingCurve(0.68, -0.55, 0.27, 1.55, duration: 1.2), duration: 1.2, c0x: 0.68, c0y: -0.55, c1x: 0.27, c1y: 1.55),
            TestCase(animation: .timingCurve(0.25, 0.1, 0.25, 1), duration: 0.35, c0x: 0.25, c0y: 0.1, c1x: 0.25, c1y: 1),
        ]
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            testCases.append(
                TestCase(
                    animation: .timingCurve(.bezier(startControlPoint: UnitPoint(x: 0.2, y: 0.8), endControlPoint: UnitPoint(x: 0.6, y: 0.1)), duration: 0.9),
                    duration: 0.9,
                    c0x: 0.2, c0y: 0.8, c1x: 0.6, c1y: 0.1
                )
            )
        }
        for testCase in testCases {
            let resolved = try XCTUnwrap(testCase.animation.resolved(), "Failed to resolve \(testCase.animation)")
            guard case .bezier(let bezier) = resolved.timingCurve else {
                XCTFail("Expected bezier timing curve for \(testCase.animation)")
                continue
            }
            XCTAssertEqual(bezier.duration, testCase.duration, accuracy: 0.0001)
            XCTAssertEqual(resolved.timingCurveDuration(defaultDuration: 0), testCase.duration, accuracy: 0.0001)

            // Polynomial coefficients of the cubic bezier through (0, 0), c0, c1, (1, 1)
            let cx = 3 * testCase.c0x
            let bx = 3 * (testCase.c1x - testCase.c0x) - cx
            let ax = 1 - cx - bx
            let cy = 3 * testCase.c0y
            let by = 3 * (testCase.c1y - testCase.c0y) - cy
            let ay = 1 - cy - by
            XCTAssertEqual(bezier.curve.ax, ax, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(bezier.curve.bx, bx, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(bezier.curve.cx, cx, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(bezier.curve.ay, ay, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(bezier.curve.by, by, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(bezier.curve.cy, cy, accuracy: 0.0001, "\(testCase.animation)")

            #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
            let function = bezier.curve.toCoreAnimation()
            var p1: [Float] = [0, 0]
            var p2: [Float] = [0, 0]
            function.getControlPoint(at: 1, values: &p1)
            function.getControlPoint(at: 2, values: &p2)
            XCTAssertEqual(p1[0], Float(testCase.c0x), accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(p1[1], Float(testCase.c0y), accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(p2[0], Float(testCase.c1x), accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(p2[1], Float(testCase.c1y), accuracy: 0.0001, "\(testCase.animation)")
            #endif
        }
    }

    func testFluidSpringTimingCurve() throws {
        let timingCurve = try XCTUnwrap(Animation.spring(duration: 0.5).timingCurve)
        guard case .fluidSpring(let fluidSpring) = timingCurve else {
            return XCTFail("Expected fluid spring timing curve")
        }
        XCTAssertEqual(fluidSpring.duration, 0.5)
        XCTAssertEqual(fluidSpring.dampingFraction, 1.0)
        XCTAssertEqual(fluidSpring.blendDuration, 0)
        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
            XCTAssertEqual(fluidSpring.delay, 0)
        }
    }

    func testFluidSpringTimingCurveParameters() throws {
        struct TestCase {
            var animation: Animation
            var duration: Double
            var dampingFraction: Double
            var blendDuration: TimeInterval
        }
        var testCases = [
            TestCase(animation: .spring(), duration: 0.5, dampingFraction: 1.0, blendDuration: 0),
            TestCase(animation: .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2), duration: 0.3, dampingFraction: 0.6, blendDuration: 0.2),
            TestCase(animation: .spring(response: 1.5, dampingFraction: 0.1, blendDuration: 1), duration: 1.5, dampingFraction: 0.1, blendDuration: 1),
            TestCase(animation: .interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.4), duration: 0.2, dampingFraction: 0.7, blendDuration: 0.4),
        ]
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            testCases += [
                TestCase(animation: .spring(), duration: 0.5, dampingFraction: 1, blendDuration: 0),
                TestCase(animation: .spring(duration: 0.8, bounce: 0.3, blendDuration: 0.1), duration: 0.8, dampingFraction: 0.7, blendDuration: 0.1),
                TestCase(animation: .spring(duration: 0.4, bounce: -0.5, blendDuration: 0), duration: 0.4, dampingFraction: 2, blendDuration: 0),
                TestCase(animation: .spring(Spring(duration: 0.4, bounce: 0.2), blendDuration: 0.3), duration: 0.4, dampingFraction: 0.8, blendDuration: 0.3),
                TestCase(animation: .spring(Spring(mass: 2, stiffness: 50, damping: 8), blendDuration: 0.3), duration: 1.2566370614359172, dampingFraction: 0.4, blendDuration: 0.3),
                TestCase(animation: .smooth(duration: 0.6, extraBounce: 0.1), duration: 0.6, dampingFraction: 0.9, blendDuration: 0),
                TestCase(animation: .snappy(duration: 0.3, extraBounce: 0.05), duration: 0.3, dampingFraction: 0.8, blendDuration: 0),
                TestCase(animation: .bouncy(duration: 0.7, extraBounce: 0.2), duration: 0.7, dampingFraction: 0.5, blendDuration: 0),
                TestCase(animation: .smooth, duration: 0.5, dampingFraction: 1, blendDuration: 0),
                TestCase(animation: .snappy, duration: 0.5, dampingFraction: 0.85, blendDuration: 0),
                TestCase(animation: .bouncy, duration: 0.5, dampingFraction: 0.7, blendDuration: 0),
            ]
        }
        for testCase in testCases {
            let resolved = try XCTUnwrap(testCase.animation.resolved(), "Failed to resolve \(testCase.animation)")
            guard case .fluidSpring(let fluidSpring) = resolved.timingCurve else {
                XCTFail("Expected fluid spring timing curve for \(testCase.animation)")
                continue
            }
            XCTAssertEqual(fluidSpring.duration, testCase.duration, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(fluidSpring.dampingFraction, testCase.dampingFraction, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(fluidSpring.blendDuration, testCase.blendDuration, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(fluidSpring.initialVelocity, log(testCase.dampingFraction) / testCase.duration, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(resolved.timingCurveDuration(defaultDuration: 0), testCase.duration, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(resolved.delay, 0)
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                XCTAssertEqual(fluidSpring.delay, 0)
            }

            let modified = try XCTUnwrap(testCase.animation.delay(0.5).speed(2).resolved())
            XCTAssertEqual(modified.timingCurve, resolved.timingCurve)
            XCTAssertEqual(modified.delay, 0.5)
            XCTAssertEqual(modified.speed, 2)
            XCTAssertEqual(modified.duration(defaultDuration: 0), testCase.duration / 2, accuracy: 0.0001)
        }
    }

    func testSpringTimingCurveParameters() throws {
        struct TestCase {
            var animation: Animation
            var mass: Double
            var stiffness: Double
            var damping: Double
            var initialVelocity: Double
            var duration: TimeInterval
        }
        var testCases = [
            TestCase(animation: .interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 0), mass: 1, stiffness: 100, damping: 10, initialVelocity: 0, duration: 1.26),
            TestCase(animation: .interpolatingSpring(mass: 2, stiffness: 50, damping: 8, initialVelocity: 3), mass: 2, stiffness: 50, damping: 8, initialVelocity: 3, duration: 3.15),
            TestCase(animation: .interpolatingSpring(mass: 0.5, stiffness: 300, damping: 1, initialVelocity: -4), mass: 0.5, stiffness: 300, damping: 1, initialVelocity: -4, duration: 6.29),
            TestCase(animation: .interpolatingSpring(stiffness: 170, damping: 26), mass: 1, stiffness: 170, damping: 26, initialVelocity: 0, duration: 0.48),
        ]
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            testCases += [
                // duration/bounce are normalized to a unit mass spring
                TestCase(animation: .interpolatingSpring(duration: 0.6, bounce: 0.2, initialVelocity: 1), mass: 1, stiffness: pow(2 * .pi / 0.6, 2), damping: 4 * .pi * 0.8 / 0.6, initialVelocity: 1, duration: 0.75),
                TestCase(animation: .interpolatingSpring(duration: 1, bounce: 0, initialVelocity: -2), mass: 1, stiffness: pow(2 * .pi, 2), damping: 4 * .pi, initialVelocity: -2, duration: 1),
                TestCase(animation: .interpolatingSpring(Spring(mass: 1.5, stiffness: 80, damping: 6), initialVelocity: 2), mass: 1, stiffness: 80 / 1.5, damping: 6 / 1.5, initialVelocity: 2, duration: 3.15),
            ]
        }
        for testCase in testCases {
            let resolved = try XCTUnwrap(testCase.animation.resolved(), "Failed to resolve \(testCase.animation)")
            guard case .spring(let spring) = resolved.timingCurve else {
                XCTFail("Expected spring timing curve for \(testCase.animation)")
                continue
            }
            XCTAssertEqual(spring.mass, testCase.mass, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(spring.stiffness, testCase.stiffness, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(spring.damping, testCase.damping, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(spring.initialVelocity, testCase.initialVelocity, accuracy: 0.0001, "\(testCase.animation)")
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                XCTAssertEqual(spring.timingCurve, .linear, "\(testCase.animation)")
            }
            XCTAssertEqual(spring.duration, testCase.duration, accuracy: 0.0001, "\(testCase.animation)")
            XCTAssertEqual(resolved.timingCurveDuration(defaultDuration: 0), testCase.duration, accuracy: 0.0001, "\(testCase.animation)")

            let modified = try XCTUnwrap(testCase.animation.delay(0.25).speed(0.5).repeatCount(2, autoreverses: true).resolved())
            XCTAssertEqual(modified.timingCurve, resolved.timingCurve)
            XCTAssertEqual(modified.delay, 0.25)
            XCTAssertEqual(modified.speed, 0.5)
            XCTAssertEqual(modified.repeatCount, 2)
            XCTAssertTrue(modified.autoreverses)

            #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
            let springAnimation = try XCTUnwrap(modified.toCoreAnimation() as? CASpringAnimation)
            XCTAssertEqual(springAnimation.mass, testCase.mass, accuracy: 0.0001)
            XCTAssertEqual(springAnimation.stiffness, testCase.stiffness, accuracy: 0.0001)
            XCTAssertEqual(springAnimation.damping, testCase.damping, accuracy: 0.0001)
            XCTAssertEqual(springAnimation.initialVelocity, testCase.initialVelocity, accuracy: 0.0001)
            XCTAssertEqual(springAnimation.speed, 0.5)
            #endif
        }
    }

    func testSpringTimingCurve() throws {
        let timingCurve = try XCTUnwrap(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 0).timingCurve)
        guard case .spring(let spring) = timingCurve else {
            return XCTFail("Expected spring timing curve")
        }
        XCTAssertEqual(spring.mass, 1)
        XCTAssertEqual(spring.stiffness, 100)
        XCTAssertEqual(spring.damping, 10)
        XCTAssertEqual(spring.initialVelocity, 0)
        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
            XCTAssertEqual(spring.timingCurve, .linear)
        }
        XCTAssertEqual(Animation.interpolatingSpring(duration: 0.5).duration(defaultDuration: 1), 0.5)
        XCTAssertEqual(Animation.interpolatingSpring(duration: 0.25).duration(defaultDuration: 1), 0.25)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    func testCustomTimingCurve() throws {
        struct MyAnimation: CustomAnimation {
            var duration: TimeInterval

            func animate<V: VectorArithmetic>(
                value: V,
                time: TimeInterval,
                context: inout AnimationContext<V>
            ) -> V? {
                value.scaled(by: time)
            }
        }
        XCTAssertEqual(Animation(MyAnimation(duration: 0.3)).duration(defaultDuration: 1), 0.3)
        XCTAssertEqual(Animation(MyAnimation(duration: 0.3)).delay(1).delay, 1)
        XCTAssertEqual(Animation(MyAnimation(duration: 0.3)).speed(2).speed, 2)
    }

    func testCodable() throws {
        var animations: [Animation] = [
            .default,
            .linear(duration: 0.3).delay(1).speed(2),
            .easeIn(duration: 0.4).repeatForever(autoreverses: false),
            .easeOut(duration: 0.6).speed(0.5),
            .easeInOut(duration: 0.5).repeatCount(2, autoreverses: true),
            .timingCurve(0.68, -0.55, 0.27, 1.55, duration: 1.2).delay(0.5),
            .spring(),
            .spring(response: 0.3, dampingFraction: 0.5).delay(1),
            .spring(response: 1.5, dampingFraction: 0.1, blendDuration: 1).speed(3),
            .interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.4),
            .interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 2).delay(1),
            .interpolatingSpring(mass: 0.5, stiffness: 300, damping: 1, initialVelocity: -4).repeatCount(3, autoreverses: false),
        ]
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            animations += [
                .spring(duration: 0.8, bounce: 0.3, blendDuration: 0.1),
                .bouncy(duration: 0.7, extraBounce: 0.2).delay(0.1),
                .interpolatingSpring(duration: 0.6, bounce: 0.2, initialVelocity: 1),
                .interpolatingSpring(Spring(mass: 1.5, stiffness: 80, damping: 6), initialVelocity: 2).speed(2),
            ]
        }
        for animation in animations {
            let resolved = try XCTUnwrap(animation.resolved(), "Failed to resolve \(animation)")
            let data = try JSONEncoder().encode(resolved)
            let decoded = try JSONDecoder().decode(Animation.Resolved.self, from: data)
            XCTAssertEqual(decoded, resolved)
        }
    }

    #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
    func testToCoreAnimation() throws {
        let linear = try XCTUnwrap(Animation.linear(duration: 0.3).speed(2).toCoreAnimation())
        XCTAssertFalse(linear is CASpringAnimation)
        XCTAssertEqual(linear.duration, 0.3, accuracy: 0.0001)
        XCTAssertEqual(linear.speed, 2)
        XCTAssertEqual(linear.fillMode, .backwards)

        let defaultAnimation = try XCTUnwrap(Animation.default.toCoreAnimation())
        XCTAssertEqual(defaultAnimation.duration, 0.35)

        let spring = try XCTUnwrap(Animation.spring(response: 0.5, dampingFraction: 1).toCoreAnimation())
        let springAnimation = try XCTUnwrap(spring as? CASpringAnimation)
        XCTAssertEqual(springAnimation.mass, 1)
        XCTAssertGreaterThan(springAnimation.stiffness, 0)
        XCTAssertGreaterThan(springAnimation.damping, 0)

        let delayed = try XCTUnwrap(Animation.linear(duration: 0.3).delay(10).toCoreAnimation())
        XCTAssertGreaterThan(delayed.beginTime, CACurrentMediaTime() + 5)
    }

    func testBezierCurveToCoreAnimation() throws {
        let timingCurve = try XCTUnwrap(Animation.linear(duration: 1).timingCurve)
        guard case .bezier(let bezier) = timingCurve else {
            return XCTFail("Expected bezier timing curve")
        }
        let function = bezier.curve.toCoreAnimation()
        var p1: [Float] = [0, 0]
        var p2: [Float] = [0, 0]
        function.getControlPoint(at: 1, values: &p1)
        function.getControlPoint(at: 2, values: &p2)
        // A linear curve has control points along the diagonal
        XCTAssertEqual(p1[0], p1[1], accuracy: 0.0001)
        XCTAssertEqual(p2[0], p2[1], accuracy: 0.0001)
    }
    #endif
}
