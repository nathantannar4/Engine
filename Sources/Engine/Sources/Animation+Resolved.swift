//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

extension Animation {

    public func duration(defaultDuration: CGFloat) -> TimeInterval {
        guard let resolved = Resolved(animation: self) else { return defaultDuration }
        switch resolved.timingCurve {
        case .default:
            return defaultDuration / resolved.speed
        default:
            return (resolved.timingCurve.duration ?? defaultDuration) / resolved.speed
        }
    }

    public var delay: TimeInterval? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.delay
    }

    public var speed: Double? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.speed
    }

    public func resolved() -> Resolved? {
        Resolved(animation: self)
    }

    public struct Resolved: Codable, Equatable {
        public enum TimingCurve: Codable, Equatable {
            case `default`

            public struct CustomAnimation: Codable, Equatable {
                public var duration: TimeInterval?
            }
            case custom(CustomAnimation)

            public struct BezierAnimation: Codable, Equatable {
                public struct AnimationCurve: Codable, Equatable {
                    public var ax: Double
                    public var bx: Double
                    public var cx: Double
                    public var ay: Double
                    public var by: Double
                    public var cy: Double
                }

                public var duration: TimeInterval
                public var curve: AnimationCurve
            }
            case bezier(BezierAnimation)

            public struct SpringAnimation: Codable, Equatable {
                public var mass: Double
                public var stiffness: Double
                public var damping: Double
                public var initialVelocity: Double
            }
            case spring(SpringAnimation)

            public struct FluidSpringAnimation: Codable, Equatable {
                public var duration: Double
                public var dampingFraction: Double
                public var blendDuration: TimeInterval
            }
            case fluidSpring(FluidSpringAnimation)

            init?(animator: Any) {
                func project<T>(_ animator: T) -> TimingCurve? {
                    switch _typeName(T.self, qualified: false) {
                    case "DefaultAnimation":
                        return .default
                    case "BezierAnimation":
                        guard MemoryLayout<BezierAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let bezier = unsafeBitCast(animator, to: BezierAnimation.self)
                        return .bezier(bezier)
                    case "SpringAnimation":
                        guard MemoryLayout<SpringAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let spring = unsafeBitCast(animator, to: SpringAnimation.self)
                        return .spring(spring)
                    case "FluidSpringAnimation":
                        guard MemoryLayout<FluidSpringAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let fluidSpring = unsafeBitCast(animator, to: FluidSpringAnimation.self)
                        return .fluidSpring(fluidSpring)
                    default:
                        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                            guard animator is (any SwiftUI.CustomAnimation) else { return nil }
                            let duration = Mirror(reflecting: animator).descendant("duration") as? TimeInterval
                            return .custom(CustomAnimation(duration: duration))
                        }
                        return nil
                    }
                }
                guard let timingCurve = _openExistential(animator, do: project) else {
                    return nil
                }
                self = timingCurve
            }

            public var duration: TimeInterval? {
                switch self {
                case .default:
                    return nil
                case .custom(let custom):
                    return custom.duration
                case .bezier(let bezierCurve):
                    return bezierCurve.duration
                case .spring(let springCurve):
                    let naturalFrequency = sqrt(springCurve.stiffness / springCurve.mass)
                    let dampingRatio = springCurve.damping / (2.0 * naturalFrequency)
                    guard dampingRatio < 1 else {
                        let duration = 2 * .pi / (naturalFrequency * dampingRatio)
                        return duration
                    }
                    let decayRate = dampingRatio * naturalFrequency
                    let duration = -log(0.01) / decayRate
                    return duration
                case .fluidSpring(let fluidSpringCurve):
                    return fluidSpringCurve.duration + fluidSpringCurve.blendDuration
                }
            }
        }

        public var timingCurve: TimingCurve
        public var delay: TimeInterval
        public var speed: Double

        public init(
            timingCurve: TimingCurve,
            delay: TimeInterval,
            speed: Double
        ) {
            self.timingCurve = timingCurve
            self.delay = delay
            self.speed = speed
        }

        public init?(animation: Animation) {
            var animator: Any
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                animator = animation.base
            } else {
                guard let base = Mirror(reflecting: animation).descendant("base") else {
                    return nil
                }
                animator = base
            }
            var delay: TimeInterval = 0
            var speed: TimeInterval = 1
            var mirror = Mirror(reflecting: animator)
            while let base = mirror.descendant("_base") ?? mirror.descendant("base") ?? mirror.descendant("animation") {
                if let modifier = mirror.descendant("modifier") {
                    mirror = Mirror(reflecting: modifier)
                }
                if let d = mirror.descendant("delay") as? TimeInterval {
                    delay += d
                }
                if let s = mirror.descendant("speed") as? TimeInterval {
                    speed *= s
                }
                animator = base
                mirror = Mirror(reflecting: animator)
            }
            guard let timingCurve = TimingCurve(animator: animator) else {
                return nil
            }
            self.timingCurve = timingCurve
            self.delay = delay
            self.speed = speed
        }
    }
}
