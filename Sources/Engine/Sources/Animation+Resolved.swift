//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

extension Animation {

    /// The duration of the animation, factoring in the speed
    public func duration(defaultDuration: TimeInterval) -> TimeInterval {
        guard let resolved = Resolved(animation: self) else { return defaultDuration }
        return resolved.duration(defaultDuration: defaultDuration)
    }

    /// The duration of the animation
    public func timingCurveDuration(defaultDuration: TimeInterval) -> TimeInterval {
        guard let resolved = Resolved(animation: self) else { return defaultDuration }
        return resolved.timingCurveDuration(defaultDuration: defaultDuration)
    }

    /// The delay of the animation
    public var delay: TimeInterval? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.delay
    }

    /// The speed of the animation
    public var speed: TimeInterval? {
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

    /// The timing curve of the animation
    public var timingCurve: Resolved.TimingCurve? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.timingCurve
    }

    #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
    public func toCoreAnimation() -> CABasicAnimation? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.toCoreAnimation()
    }
    #endif

    /// The deconstructed animation
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
                enum Payload: Codable, Equatable, Sendable {
                    struct V8Payload: Codable, Equatable, Sendable {
                        var mass: Double
                        var stiffness: Double
                        var damping: Double
                        var initialVelocity: Double
                        var timingCurve: UnitCurveTypeLayout
                    }
                    case v8(V8Payload)

                    struct V1Payload: Codable, Equatable, Sendable {
                        var mass: Double
                        var stiffness: Double
                        var damping: Double
                        var initialVelocity: Double
                    }
                    case v1(V1Payload)

                    var mass: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.mass
                            case .v1(let payload):
                                return payload.mass
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.mass = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.mass = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    var stiffness: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.stiffness
                            case .v1(let payload):
                                return payload.stiffness
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.stiffness = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.stiffness = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    var damping: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.damping
                            case .v1(let payload):
                                return payload.damping
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.damping = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.damping = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    var initialVelocity: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.initialVelocity
                            case .v1(let payload):
                                return payload.initialVelocity
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.initialVelocity = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.initialVelocity = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
                    var timingCurve: UnitCurve? {
                        switch self {
                        case .v8(let payload):
                            return UnitCurve(payload.timingCurve)
                        case .v1:
                            return nil
                        }
                    }
                }

                var payload: Payload

                public var mass: Double {
                    get { payload.mass }
                    set { payload.mass = newValue }
                }

                public var stiffness: Double {
                    get { payload.stiffness }
                    set { payload.stiffness = newValue }
                }

                public var damping: Double {
                    get { payload.damping }
                    set { payload.damping = newValue }
                }

                public var initialVelocity: Double {
                    get { payload.initialVelocity }
                    set { payload.initialVelocity = newValue }
                }

                @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
                public var timingCurve: UnitCurve? {
                    payload.timingCurve
                }

                /// The time for the spring to settle, `Spring.duration` is not used as it
                /// is the perceptual duration which is shorter than the animation runs for
                public var duration: TimeInterval {
                    guard mass > 0, stiffness > 0, damping > 0 else { return 0 }
                    let naturalFrequency = sqrt(stiffness / mass)
                    let dampingRatio = damping / (2.0 * mass * naturalFrequency)
                    let threshold = 0.00185
                    let duration: TimeInterval = {
                        if dampingRatio < 1.0 {
                            let decayRate = dampingRatio * naturalFrequency
                            return -log(threshold) / decayRate
                        } else {
                            let root = dampingRatio - sqrt(max(0, dampingRatio * dampingRatio - 1.0))
                            let decayRate = naturalFrequency * root
                            guard decayRate > 0 else { return 0 }
                            return -log(threshold) / decayRate
                        }
                    }()
                    return (duration * 100).rounded() / 100
                }
            }
            case spring(SpringAnimation)

            public struct FluidSpringAnimation: Codable, Equatable, Sendable {
                enum Payload: Codable, Equatable, Sendable {
                    struct V8Payload: Codable, Equatable, Sendable {
                        var duration: Double
                        var dampingFraction: Double
                        var blendDuration: TimeInterval
                        var delay: TimeInterval
                    }
                    case v8(V8Payload)

                    struct V1Payload: Codable, Equatable, Sendable {
                        var duration: Double
                        var dampingFraction: Double
                        var blendDuration: TimeInterval
                    }
                    case v1(V1Payload)

                    var duration: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.duration
                            case .v1(let payload):
                                return payload.duration
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.duration = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.duration = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    var dampingFraction: Double {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.dampingFraction
                            case .v1(let payload):
                                return payload.dampingFraction
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.dampingFraction = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.dampingFraction = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    var blendDuration: TimeInterval {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.blendDuration
                            case .v1(let payload):
                                return payload.blendDuration
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.blendDuration = newValue
                                self = .v8(payload)
                            case .v1(var payload):
                                payload.blendDuration = newValue
                                self = .v1(payload)
                            }
                        }
                    }

                    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
                    var delay: TimeInterval {
                        get {
                            switch self {
                            case .v8(let payload):
                                return payload.delay
                            case .v1:
                                return 0
                            }
                        }
                        set {
                            switch self {
                            case .v8(var payload):
                                payload.delay = newValue
                                self = .v8(payload)
                            case .v1:
                                break
                            }
                        }
                    }
                }

                var payload: Payload

                public var duration: Double {
                    get { payload.duration }
                    set { payload.duration = newValue }
                }

                public var dampingFraction: Double {
                    get { payload.dampingFraction }
                    set { payload.dampingFraction = newValue }
                }

                public var blendDuration: TimeInterval {
                    get { payload.blendDuration }
                    set { payload.blendDuration = newValue }
                }

                @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
                public var delay: TimeInterval {
                    get { payload.delay }
                    set { payload.delay = newValue }
                }

                public var initialVelocity: Double {
                    guard duration > 0, dampingFraction > 0 else { return 0 }
                    let initialVelocity = duration > 0 ? log(dampingFraction) / duration : 0
                    return initialVelocity
                }
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
                        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                            guard MemoryLayout<SpringAnimation.Payload.V8Payload>.size == MemoryLayout<T>.size else {
                                return nil
                            }
                            let payload = unsafeBitCast(animator, to: SpringAnimation.Payload.V8Payload.self)
                            return .spring(SpringAnimation(payload: .v8(payload)))
                        } else {
                            guard MemoryLayout<SpringAnimation.Payload.V1Payload>.size == MemoryLayout<T>.size else {
                                return nil
                            }
                            let payload = unsafeBitCast(animator, to: SpringAnimation.Payload.V1Payload.self)
                            return .spring(SpringAnimation(payload: .v1(payload)))
                        }
                    case "FluidSpringAnimation":
                        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                            guard MemoryLayout<FluidSpringAnimation.Payload.V8Payload>.size == MemoryLayout<T>.size else {
                                return nil
                            }
                            let payload = unsafeBitCast(animator, to: FluidSpringAnimation.Payload.V8Payload.self)
                            return .fluidSpring(FluidSpringAnimation(payload: .v8(payload)))
                        } else {
                            guard MemoryLayout<FluidSpringAnimation.Payload.V1Payload>.size == MemoryLayout<T>.size else {
                                return nil
                            }
                            let payload = unsafeBitCast(animator, to: FluidSpringAnimation.Payload.V1Payload.self)
                            return .fluidSpring(FluidSpringAnimation(payload: .v1(payload)))
                        }
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
                case .custom(let customCurve):
                    return customCurve.duration
                case .bezier(let bezierCurve):
                    return bezierCurve.duration
                case .spring(let springCurve):
                    return springCurve.duration
                case .fluidSpring(let fluidSpringCurve):
                    return fluidSpringCurve.duration
                }
            }
        }

        public var timingCurve: TimingCurve
        public var delay: TimeInterval
        public var speed: TimeInterval
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
                                let (sum, overflowed) = repeatCount.addingReportingOverflow(r)
                                repeatCount = overflowed ? .max : sum
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
                if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *),
                    case .fluidSpring(let fluidSpring) = timingCurve
                {
                    delay += fluidSpring.delay
                }
                self.timingCurve = timingCurve
                self.delay = delay
                self.speed = speed
                self.repeatCount = repeatCount
                self.autoreverses = autoreverses
            }
        }

        /// The duration of the animation, factoring in the speed
        public func duration(defaultDuration: TimeInterval) -> TimeInterval {
            let timingCurveDuration = timingCurveDuration(defaultDuration: defaultDuration)
            return timingCurveDuration / speed
        }

        /// The duration of the animation
        public func timingCurveDuration(defaultDuration: TimeInterval) -> TimeInterval {
            return timingCurve.duration ?? defaultDuration
        }
    }
}

struct UnitCurveTypeLayout: Codable, Equatable, Sendable {
    var p0: Double
    var p1: Double
    var p2: Double
    var p3: Double
    var tag: UInt8
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension UnitCurve {

    init?(_ layout: UnitCurveTypeLayout) {
        guard MemoryLayout<UnitCurveTypeLayout>.size == MemoryLayout<UnitCurve>.size else {
            return nil
        }
        self = unsafeBitCast(layout, to: UnitCurve.self)
    }
}

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)

extension Animation.Resolved {

    public func toCoreAnimation() -> CABasicAnimation {
        switch timingCurve {
        case .default, .custom:
            let duration = timingCurveDuration(defaultDuration: 0.35)
            let basicAnimation = CABasicAnimation()
            basicAnimation.timingFunction = CAMediaTimingFunction(name: .default)
            basicAnimation.duration = duration
            basicAnimation.speed = Float(speed)
            basicAnimation.beginTime = CACurrentMediaTime() + delay
            basicAnimation.fillMode = .backwards
            return basicAnimation

        case .bezier(let bezierAnimation):
            let basicAnimation = CABasicAnimation()
            basicAnimation.timingFunction = bezierAnimation.curve.toCoreAnimation()
            basicAnimation.duration = bezierAnimation.duration
            basicAnimation.speed = Float(speed)
            basicAnimation.beginTime = CACurrentMediaTime() + delay
            basicAnimation.fillMode = .backwards
            return basicAnimation

        case .spring(let springCurve):
            let springAnimation = CASpringAnimation()
            springAnimation.mass = springCurve.mass
            springAnimation.stiffness = springCurve.stiffness
            springAnimation.damping = springCurve.damping
            springAnimation.initialVelocity = springCurve.initialVelocity
            springAnimation.speed = Float(speed)
            springAnimation.beginTime = CACurrentMediaTime() + delay
            springAnimation.fillMode = .backwards
            return springAnimation

        case .fluidSpring(let fluidSpringCurve):
            let initialVelocity = fluidSpringCurve.initialVelocity
            let dampingRatio = fluidSpringCurve.dampingFraction
            let stiffness = pow((2 * .pi) / fluidSpringCurve.duration, 2)
            let damping = dampingRatio * 2 * sqrt(stiffness)
            let springAnimation = CASpringAnimation()
            springAnimation.initialVelocity = initialVelocity
            springAnimation.mass = 1
            springAnimation.stiffness = stiffness
            springAnimation.damping = damping
            springAnimation.speed = Float(speed)
            springAnimation.beginTime = CACurrentMediaTime() + delay
            springAnimation.fillMode = .backwards
            return springAnimation

        }
    }
}

extension Animation.Resolved.TimingCurve.BezierAnimation.AnimationCurve {

    public func toCoreAnimation() -> CAMediaTimingFunction {
        return CAMediaTimingFunction(
            controlPoints:
                Float(cx / 3), Float(cy / 3),
                Float(cx - (cx - bx) / 3), Float(cy - (cy - by) / 3)
        )
    }
}

#endif

// MARK: - Previews

struct AnimationResolved_Previews: PreviewProvider {
    struct AnimationPreview: View {
        var label: String
        var animation: Animation

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text(label)
                }

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

                Divider()

                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                    AnimationPreview(label: "PreviewAnimation", animation: .init(PreviewAnimation()).speed(2).delay(1))
                }

                Divider()

                AnimationPreview(label: "SpringAnimation", animation: .interpolatingSpring())

                AnimationPreview(label: "SpringAnimation", animation: .interpolatingSpring(mass: 1, stiffness: 10, damping: 5, initialVelocity: 0).speed(2).delay(1))

                Divider()

                AnimationPreview(label: "FluidSpringAnimation", animation: .interactiveSpring())

                AnimationPreview(label: "FluidSpringAnimation", animation: .bouncy.speed(2).delay(1))

                Divider()

                AnimationPreview(label: "BezierAnimation", animation: .easeInOut.speed(2).delay(1))

                AnimationPreview(label: "BezierAnimation", animation: .linear)
            }
        }
    }
}
