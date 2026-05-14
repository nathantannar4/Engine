//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

extension Animation {

    /// The duration of the animation
    public func duration(defaultDuration: CGFloat) -> TimeInterval {
        guard let resolved = Resolved(animation: self) else { return defaultDuration }
        switch resolved.timingCurve {
        case .default:
            return defaultDuration / resolved.speed
        default:
            return (resolved.timingCurve.duration ?? defaultDuration) / resolved.speed
        }
    }

    /// The delay of the animation
    public var delay: TimeInterval? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.delay
    }

    /// The speed of the animation
    public var speed: Double? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.speed
    }

    /// The repeat count of the animation, `.max` indicates forever
    public var repeatCount: Int? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.repeatCount
    }

    /// The flag indicating the animation should auto reverse
    public var autoreverses: Bool? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.autoreverses
    }

    /// The delay of the animation
    public func resolved() -> Resolved? {
        Resolved(animation: self)
    }

    /// A deconstructed opaque `Animation`
    public struct Resolved: Codable, Equatable, Sendable {
        public enum TimingCurve: Codable, Equatable, Sendable {
            case `default`

            public struct CustomAnimation: Codable, Equatable, Sendable {
                public var duration: TimeInterval?
            }
            case custom(CustomAnimation)

            public struct BezierAnimation: Codable, Equatable, Sendable {
                public struct AnimationCurve: Codable, Equatable, Sendable {
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

            public struct SpringAnimation: Codable, Equatable, Sendable {
                public var mass: Double
                public var stiffness: Double
                public var damping: Double
                public var initialVelocity: Double
            }
            case spring(SpringAnimation)

            public struct FluidSpringAnimation: Codable, Equatable, Sendable {
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
                            let duration = try? swift_getFieldValue("duration", TimeInterval.self, animator)
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
        public var repeatCount: Int
        public var autoreverses: Bool

        public init?(animation: Animation) {
            if animation == .default {
                self.timingCurve = .default
                self.delay = 0
                self.speed = 1
                self.repeatCount = 0
                self.autoreverses = false
            } else {
                var animator: Any
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                    animator = animation.base
                } else {
                    animator = animation
                }
                var delay: TimeInterval = 0
                var speed: TimeInterval = 1
                var repeatCount: Int = 0
                var autoreverses = false
                func getNext(animator: Any) -> Any? {
                    if let next = try? swift_getFieldValue("base", Any.self, animator) {
                        return next
                    }
                    if let next = try? swift_getFieldValue("_base", Any.self, animator) {
                        return next
                    }
                    if let next = try? swift_getFieldValue("animation", Any.self, animator) {
                        return next
                    }
                    return nil
                }
                while let next = getNext(animator: animator) {
                    if let modifier = try? swift_getFieldValue("modifier", Any.self, animator) {
                        let name = String(describing: type(of: modifier))
                        switch name {
                        case "RepeatAnimation":
                            if let r = try? swift_getFieldValue("repeatCount", Optional<Int>.self, modifier) {
                                repeatCount += r
                            } else {
                                repeatCount = .max
                            }
                            if let a = try? swift_getFieldValue("autoreverses", Bool.self, modifier) {
                                autoreverses = autoreverses || a
                            }
                        case "SpeedAnimation":
                            if let s = try? swift_getFieldValue("speed", TimeInterval.self, modifier) {
                                speed *= s
                            }
                        case "DelayAnimation":
                            if let d = try? swift_getFieldValue("delay", TimeInterval.self, modifier) {
                                delay += d
                            }
                        default:
                            os_log(.debug, log: .default, "Failed to resolve Animation modifier %{public}@. Please file an issue.", name)
                        }
                    }
                    animator = next
                }
                guard let timingCurve = TimingCurve(animator: animator) else {
                    return nil
                }
                self.timingCurve = timingCurve
                self.delay = delay
                self.speed = speed
                self.repeatCount = repeatCount
                self.autoreverses = autoreverses
            }
        }
    }
}

// MARK: - Previews

struct AnimationResolved_Previews: PreviewProvider {
    struct AnimationPreview: View {
        var label: String
        var animation: Animation

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(label)

                VStack(alignment: .leading) {
                    Text(verbatim: "Delay: \(animation.delay as Any)")
                    Text(verbatim: "Speed: \(animation.speed as Any)")
                    Text(verbatim: "Repeat Count: \(animation.repeatCount as Any)")
                    Text(verbatim: "Autoreverses: \(animation.autoreverses as Any)")
                    if let resolved = animation.resolved() {
                        Text(verbatim: "Resolved: \(resolved.timingCurve)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    struct PreviewAnimation: CustomAnimation {
        func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
            return value
        }
    }

    static var previews: some View {
        ScrollView {
            VStack {
                AnimationPreview(label: "Default", animation: .default)
                AnimationPreview(label: "Default Fast", animation: .default.speed(2))
                AnimationPreview(label: "Default Faster", animation: .default.speed(2).speed(2))
                AnimationPreview(label: "Default Slow", animation: .default.speed(0.5))
                AnimationPreview(label: "Default Delayed", animation: .default.delay(1))
                AnimationPreview(label: "Default Slow Delayed", animation: .default.delay(1).speed(0.5).delay(1))
                AnimationPreview(label: "Default Repeat", animation: .default.repeatCount(1))
                AnimationPreview(label: "Default Repeated", animation: .default.repeatForever(autoreverses: true))

                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                    AnimationPreview(label: "PreviewAnimation", animation: .init(PreviewAnimation()).speed(2).delay(1))
                }

                AnimationPreview(label: "SpringAnimation", animation: .spring.speed(2).delay(1))

                AnimationPreview(label: "FluidSpringAnimation", animation: .bouncy.speed(2).delay(1))

                AnimationPreview(label: "BezierAnimation", animation: .easeInOut.speed(2).delay(1))
            }
        }
    }
}
