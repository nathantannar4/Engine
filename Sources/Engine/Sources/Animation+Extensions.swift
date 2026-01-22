//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(visionOS)

import SwiftUI

extension Animation {

    public var timingParameters: UITimingCurveProvider? {
        guard let resolved = Resolved(animation: self) else { return nil }
        switch resolved.timingCurve {
        case .default, .custom:
            return nil
        case .bezier, .spring, .fluidSpring:
            return AnimationTimingCurveProvider(
                timingCurve: resolved.timingCurve
            )
        }
    }

}

extension UIViewPropertyAnimator {

    public convenience init(
        animation: Animation?,
        defaultDuration: TimeInterval = 0.35,
        defaultCompletionCurve: UIView.AnimationCurve = .easeInOut
    ) {
        if let resolved = animation?.resolved() {
            switch resolved.timingCurve {
            case .default:
                self.init(
                    duration: defaultDuration / resolved.speed,
                    curve: defaultCompletionCurve
                )
            case .custom(let animation):
                self.init(
                    duration: (animation.duration ?? defaultDuration) / resolved.speed,
                    curve: defaultCompletionCurve
                )
            case .bezier, .spring, .fluidSpring:
                let duration = (resolved.timingCurve.duration ?? defaultDuration) / resolved.speed
                self.init(
                    duration: duration,
                    timingParameters: AnimationTimingCurveProvider(
                        timingCurve: resolved.timingCurve
                    )
                )
            }
        } else {
            self.init(duration: defaultDuration, curve: defaultCompletionCurve)
        }
    }
}

extension UIView {

    @MainActor @preconcurrency
    public static func animate(
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let animation else {
            animations()
            completion?(true)
            return
        }

        let animator = UIViewPropertyAnimator(animation: animation)
        animator.addAnimations(animations)
        if let completion {
            animator.addCompletion { position in
                completion(position == .end)
            }
        }
        animator.startAnimation(afterDelay: animation.delay ?? 0)
    }

    @MainActor @preconcurrency
    public static func animate(
        with animation: Animation?,
        changes: @escaping () -> Void
    ) {
        animate(with: animation, changes: changes, completion: nil)
    }

    @MainActor @preconcurrency
    public static func animate(
        with animation: Animation?,
        changes: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        if #available(iOS 18.0, *), let animation {
            UIView.animate(
                animation,
                changes: changes,
                completion: completion
            )
        } else {
            animate(
                with: animation,
                animations: changes,
                completion: completion.map({ handler in {  _ in handler() } })
            )
        }
    }
}

@objc(EngineAnimationTimingCurveProvider)
private class AnimationTimingCurveProvider: NSObject, UITimingCurveProvider {

    let timingCurve: Animation.Resolved.TimingCurve
    nonisolated init(timingCurve: Animation.Resolved.TimingCurve) {
        self.timingCurve = timingCurve
    }

    nonisolated required init?(coder: NSCoder) {
        if let data = coder.decodeData(),
            let timingCurve = try? JSONDecoder().decode(Animation.Resolved.TimingCurve.self, from: data) {
            self.timingCurve = timingCurve
        } else {
            return nil
        }
    }

    nonisolated func encode(with coder: NSCoder) {
        if let data = try? JSONEncoder().encode(timingCurve) {
            coder.encode(data)
        }
    }

    nonisolated func copy(with zone: NSZone? = nil) -> Any {
        AnimationTimingCurveProvider(timingCurve: timingCurve)
    }


    // MARK: - UITimingCurveProvider

    var timingCurveType: UITimingCurveType {
        switch timingCurve {
        case .default, .custom:
            return .builtin
        case .bezier:
            return .cubic
        case .spring, .fluidSpring:
            return .spring
        }
    }

    var cubicTimingParameters: UICubicTimingParameters? {
        switch timingCurve {
        case .bezier(let bezierCurve):
            let curve = bezierCurve.curve
            let p1x = curve.cx / 3
            let p1y = curve.cy / 3
            let p1 = CGPoint(x: p1x, y: p1y)
            let p2x = curve.cx - (1 / 3) * (curve.cx - curve.bx)
            let p2y = curve.cy - (1 / 3) * (curve.cy - curve.by)
            let p2 = CGPoint(x: p2x, y: p2y)
            return UICubicTimingParameters(
                controlPoint1: p1,
                controlPoint2: p2
            )
        case .default, .custom, .spring, .fluidSpring:
            return nil
        }
    }

    var springTimingParameters: UISpringTimingParameters? {
        switch timingCurve {
        case .spring(let springCurve):
            return UISpringTimingParameters(
                mass: springCurve.mass,
                stiffness: springCurve.stiffness,
                damping: springCurve.damping,
                initialVelocity: CGVector(
                    dx: springCurve.initialVelocity,
                    dy: springCurve.initialVelocity
                )
            )
        case .fluidSpring(let fluidSpringCurve):
            let initialVelocity = log(fluidSpringCurve.dampingFraction) / (fluidSpringCurve.duration - fluidSpringCurve.blendDuration)
            return UISpringTimingParameters(
                dampingRatio: fluidSpringCurve.dampingFraction,
                initialVelocity: CGVector(
                    dx: initialVelocity,
                    dy: initialVelocity
                )
            )
        case .default, .custom, .bezier:
            return nil
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct Animation_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            let backgroundColor = flag ? Color.blue : Color.red
            VStack {
                HStack {
                    CustomAnimatedViewRepresentable(backgroundColor: backgroundColor)

                    CustomAnimatedViewRepresentable(backgroundColor: backgroundColor)
                        .animation(.default, value: flag)

                    CustomAnimatedViewRepresentable(backgroundColor: backgroundColor)
                        .animation(.linear(duration: 3), value: flag)
                }

                if #available(iOS 18.0, *) {
                    HStack {
                        BuiltinViewRepresentable(backgroundColor: backgroundColor)

                        BuiltinViewRepresentable(backgroundColor: backgroundColor)
                            .animation(.default, value: flag)

                        BuiltinViewRepresentable(backgroundColor: backgroundColor)
                            .animation(.linear(duration: 3), value: flag)
                    }
                }
            }
            .onTapGesture {
                flag.toggle()
            }
        }
    }

    struct CustomAnimatedViewRepresentable: UIViewRepresentable {
        var backgroundColor: Color

        func makeUIView(context: Context) -> UIView {
            UIView()
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            print("Custom", context.transaction.animation as Any)
            UIView.animate(with: context.transaction.animation) {
                uiView.backgroundColor = backgroundColor.toUIColor()
            } completion: { success in
                print("Custom", success)
            }
        }
    }

    @available(iOS 18.0, *)
    struct BuiltinViewRepresentable: UIViewRepresentable {
        var backgroundColor: Color

        func makeUIView(context: Context) -> UIView {
            UIView()
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            print("Builtin", context.transaction.animation as Any)
            context.animate {
                uiView.backgroundColor = backgroundColor.toUIColor()
            } completion: {
                print("Builtin", "done")
            }
        }
    }
}

#endif
