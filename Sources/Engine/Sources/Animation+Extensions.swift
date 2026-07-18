//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if os(iOS) || os(visionOS)

import UIKit

extension UIViewPropertyAnimator {

    public convenience init(
        animation: Animation?,
        defaultDuration: TimeInterval = 0.35,
        defaultCompletionCurve: UIView.AnimationCurve = .easeInOut
    ) {
        if let resolved = animation?.resolved() {
            let curve = resolved.speed != 1 && defaultCompletionCurve.rawValue == 7 ? UIView.AnimationCurve.easeInOut : defaultCompletionCurve
            let duration = resolved.duration(defaultDuration: defaultDuration)
            switch resolved.timingCurve {
            case .default, .custom:
                self.init(
                    duration: duration,
                    curve: curve
                )
            case .bezier, .spring, .fluidSpring:
                if duration > 0, duration.isFinite {
                    self.init(
                        duration: duration,
                        timingParameters: AnimationTimingCurveProvider(
                            timingCurve: resolved.timingCurve
                        )
                    )
                } else {
                    self.init(
                        duration: duration,
                        curve: curve
                    )
                }
            }
        } else {
            self.init(
                duration: defaultDuration,
                curve: defaultCompletionCurve
            )
        }
    }
}

extension UIView {

    public func animate(
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)? = nil
    ) {
        UIView.animate(with: animation, animations: animations, completion: completion)
    }

    public static func animate(
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)? = nil
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
}

extension Animation {

    public var timingParameters: UITimingCurveProvider? {
        guard let timingCurve else { return nil }
        return AnimationTimingCurveProvider(
            timingCurve: timingCurve
        )
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
            let initialVelocity = fluidSpringCurve.initialVelocity
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

#elseif os(macOS)

import AppKit

extension NSView {

    public func animate(
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)? = nil
    ) {
        NSView.animate(self, with: animation, animations: animations, completion: completion)
    }

    public static func animate(
        _ view: NSView,
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)? = nil
    ) {
        view.endDelayedAnimations(cancel: true)

        guard let resolved = animation?.resolved() else {
            animations()
            completion?(true)
            return
        }

        switch resolved.timingCurve {
        case .default, .custom:
            if let layer = view.layer {
                let animation = resolved.toCoreAnimation()
                layer.animate(
                    duration: animation.duration,
                    animation: animation,
                    animations: animations,
                    completion: completion
                )
            } else {
                let duration = resolved.duration(defaultDuration: 0.35)
                animate(
                    view,
                    duration: duration,
                    delay: resolved.delay,
                    timingFunction: CAMediaTimingFunction(name: .default),
                    animations: animations,
                    completion: completion
                )
            }

        case .bezier(let bezierAnimation):
            if let layer = view.layer {
                let animation = resolved.toCoreAnimation()
                layer.animate(
                    duration: animation.duration,
                    animation: animation,
                    animations: animations,
                    completion: completion
                )
            } else {
                let duration = resolved.duration(defaultDuration: 0.35)
                animate(
                    view,
                    duration: duration,
                    delay: resolved.delay,
                    timingFunction: bezierAnimation.curve.toCoreAnimation(),
                    animations: animations,
                    completion: completion
                )
            }

        case .spring(let springCurve):
            if let layer = view.layer, let animation = resolved.toCoreAnimation() as? CASpringAnimation {
                layer.animate(
                    duration: animation.settlingDuration,
                    animation: animation,
                    animations: animations,
                    completion: completion
                )
            } else {
                let duration = resolved.duration(defaultDuration: 0.35)
                animate(
                    view,
                    duration: duration,
                    delay: resolved.delay,
                    timingFunction: CAMediaTimingFunction(name: .default),
                    animations: animations,
                    completion: completion
                )
            }

        case .fluidSpring(let fluidSpringCurve):
            if let layer = view.layer, let animation = resolved.toCoreAnimation() as? CASpringAnimation {
                layer.animate(
                    duration: animation.settlingDuration,
                    animation: animation,
                    animations: animations,
                    completion: completion
                )
            } else {
                let duration = resolved.duration(defaultDuration: 0.35)
                animate(
                    view,
                    duration: duration,
                    delay: resolved.delay,
                    timingFunction: CAMediaTimingFunction(name: .default),
                    animations: animations,
                    completion: completion
                )
            }
        }
    }

    private static func animate(
        _ view: NSView,
        duration: TimeInterval,
        delay: TimeInterval,
        timingFunction: CAMediaTimingFunction,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)?
    ) {
        if delay > 0 {
            let changes = DispatchWorkItem { [weak view] in
                guard let view else { return }
                view.endDelayedAnimations(cancel: false)
                NSView.animate(
                    view,
                    duration: duration,
                    delay: 0,
                    timingFunction: timingFunction,
                    animations: animations,
                    completion: completion
                )
            }
            view.startDelayedAnimations(changes)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: changes)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = timingFunction
                context.allowsImplicitAnimation = true
                animations()
            } completionHandler: {
                if let completion {
                    MainActor.assumeIsolated { completion(true) }
                }
            }
        }
    }

    private func startDelayedAnimations(_ animations: DispatchWorkItem) {
        objc_setAssociatedObject(self, &Self.delayedAnimationsKey, animations, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func endDelayedAnimations(cancel: Bool) {
        if let animations = objc_getAssociatedObject(self, &Self.delayedAnimationsKey) as? DispatchWorkItem {
            if cancel {
                animations.cancel()
            }
            objc_setAssociatedObject(self, &Self.delayedAnimationsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static var delayedAnimationsKey: UInt = 0
}

#endif

#if os(iOS) || os(visionOS) || os(macOS)

extension CALayer {

    public func animate(
        duration: TimeInterval,
        animation: CABasicAnimation,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)?
    ) {
        CALayer.animate(
            self,
            duration: duration,
            animation: animation,
            animations: animations,
            completion: completion
        )
    }

    public static func animate(
        _ layer: CALayer,
        duration: TimeInterval,
        animation: CABasicAnimation,
        animations: @escaping () -> Void,
        completion: (@Sendable (Bool) -> Void)?
    ) {
        var delegate = layer.delegate
        while let provider = delegate as? AnimationTimingCurveDelegate {
            delegate = provider.delegate
        }
        let provider = AnimationTimingCurveDelegate(
            animation: animation,
            delegate: delegate
        )
        layer.delegate = provider

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            if layer.delegate === provider {
                layer.delegate = provider.delegate
            }
            completion?(true)
        }
        #if os(macOS)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.allowsImplicitAnimation = true
            animations()
        }
        #else
        animations()
        #endif
        CATransaction.commit()
    }
}

@objc(EngineAnimationTimingCurveDelegate)
private class AnimationTimingCurveDelegate: NSObject, CALayerDelegate {

    let animation: CABasicAnimation
    let delegate: CALayerDelegate?

    init(animation: CABasicAnimation, delegate: CALayerDelegate?) {
        self.animation = animation
        self.delegate = delegate
    }

    func display(_ layer: CALayer) {
        delegate?.display?(layer)
    }

    func draw(_ layer: CALayer, in ctx: CGContext) {
        delegate?.draw?(layer, in: ctx)
    }

    func layerWillDraw(_ layer: CALayer) {
        delegate?.layerWillDraw?(layer)
    }

    func layoutSublayers(of layer: CALayer) {
        delegate?.layoutSublayers?(of: layer)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(action(for:forKey:)) {
            return true
        }
        return delegate?.responds(to: aSelector) ?? false
    }

    func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if let action = delegate?.action?(for: layer, forKey: event), !Self.animatableKeys.contains(event) || action is NSNull {
            return action
        }

        let animation = animation.copy() as! CABasicAnimation
        animation.keyPath = event
        animation.fromValue = layer.presentation()?.value(forKeyPath: event) ?? layer.value(forKeyPath: event)
        return animation
    }

    static let animatableKeys = Set(
        [
            "backgroundColor",
            "position",
            "bounds",
            "opacity",
            "transform",
            "cornerRadius",
            "shadowOpacity",
            "shadowRadius",
            "borderWidth",
            "borderColor",
            "zPosition"
        ]
    )
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0,  *)
struct Animation_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct AnimationPreview: View {
        var cornerRadius: CGFloat
        var backgroundColor: Color

        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay {
                        Text("Shape")
                    }

                EngineAnimatedPlatformView(
                    cornerRadius: cornerRadius,
                    backgroundColor: backgroundColor
                )
                .overlay {
                    Text("Engine")
                }

                if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                    SwiftUIAnimatedPlatformView(
                        cornerRadius: cornerRadius,
                        backgroundColor: backgroundColor
                    )
                    .overlay {
                        Text("SwiftUI")
                    }
                }
            }
        }

        #if os(iOS) || os(visionOS)
        struct EngineAnimatedPlatformView: UIViewRepresentable {
            var cornerRadius: CGFloat
            var backgroundColor: Color

            func makeUIView(context: Context) -> UIView {
                return UIView()
            }

            func updateUIView(_ uiView: UIView, context: Context) {
                UIView.animate(with: context.transaction.animation) {
                    uiView.backgroundColor = backgroundColor.toUIColor()
                    uiView.layer.cornerRadius = cornerRadius
                } completion: { _ in

                }
            }
        }

        @available(iOS 18.0, visionOS 2.0, *)
        struct SwiftUIAnimatedPlatformView: UIViewRepresentable {
            var cornerRadius: CGFloat
            var backgroundColor: Color

            func makeUIView(context: Context) -> UIView {
                return UIView()
            }

            func updateUIView(_ uiView: UIView, context: Context) {
                // SwiftUI's context animate does not being the animation from the current state
                context.animate {
                    uiView.backgroundColor = backgroundColor.toUIColor()
                    uiView.layer.cornerRadius = cornerRadius
                }
            }
        }
        #else
        struct EngineAnimatedPlatformView: NSViewRepresentable {
            var cornerRadius: CGFloat
            var backgroundColor: Color

            func makeNSView(context: Context) -> NSView {
                let nsView = NSView()
                nsView.wantsLayer = true
                return nsView
            }

            func updateNSView(_ nsView: NSView, context: Context) {
                nsView.animate(with: context.transaction.animation) {
                    nsView.layer?.backgroundColor = backgroundColor.toCGColor()
                    nsView.layer?.cornerRadius = cornerRadius
                }
            }
        }

        @available(macOS 15.0, *)
        struct SwiftUIAnimatedPlatformView: NSViewRepresentable {
            var cornerRadius: CGFloat
            var backgroundColor: Color

            func makeNSView(context: Context) -> NSView {
                let nsView = NSView()
                nsView.wantsLayer = true
                return nsView
            }

            func updateNSView(_ nsView: NSView, context: Context) {
                // SwiftUI's context animate does not work for NSView
                context.animate {
                    nsView.layer?.backgroundColor = backgroundColor.toCGColor()
                    nsView.layer?.cornerRadius = cornerRadius
                }
            }
        }
        #endif
    }

    struct Preview: View {
        @State var flag = false
        @State var delay: TimeInterval = 0
        @State var speed: Double = 1

        var body: some View {
            let backgroundColor = flag ? Color.blue : Color.red
            let cornerRadius: CGFloat = flag ? 16 : 0
            let animations: [Animation?] = [
                nil,
                .default.speed(speed).delay(delay),
                .easeInOut.speed(speed).delay(delay),
                .linear.speed(speed).delay(delay),
                .spring.speed(speed).delay(delay),
                .spring().speed(speed).delay(delay),
            ]
            VStack {
                ForEach(animations) { animation in
                    AnimationPreview(
                        cornerRadius: cornerRadius,
                        backgroundColor: backgroundColor
                    )
                    .animation(animation, value: flag)
                }


                Slider(value: $delay, in: 0...3, step: 0.25) {
                    Text("Delay")
                }

                Slider(value: $speed, in: 0...2, step: 0.25) {
                    Text("Speed")
                }

                Button {
                    flag.toggle()
                } label: {
                    Text("Toggle")
                }
            }
        }
    }
}

#endif
