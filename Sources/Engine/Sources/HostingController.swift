//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

#if os(watchOS)
import WatchKit
#endif

#if os(macOS)
public typealias PlatformHostingController<Content: View> = NSHostingController<Content>
#elseif os(watchOS)
public typealias PlatformHostingController<Content: View> = WKHostingController<Content>
#else
public typealias PlatformHostingController<Content: View> = UIHostingController<Content>
#endif

#if !os(watchOS)
public protocol AnyHostingController: PlatformViewController {

    #if os(iOS) || os(tvOS) || os(visionOS)
    var disableSafeArea: Bool { get set }
    #endif
    func render()
}
#endif

#if os(iOS)
@frozen
public struct HostingControllerRootView<Content: View>: View {

    public var content: Content
    public var transaction: Transaction
    public var disablesKeyboardSafeArea: Bool

    @inlinable
    public init(
        content: Content,
        transaction: Transaction,
        disablesKeyboardSafeArea: Bool = false
    ) {
        self.content = content
        self.transaction = transaction
        self.disablesKeyboardSafeArea = disablesKeyboardSafeArea
    }

    public var body: some View {
        _Body(
            content: content,
            transaction: transaction,
            disablesKeyboardSafeArea: disablesKeyboardSafeArea
        )
    }

    private struct _Body: VersionedView {
        var content: Content
        var transaction: Transaction
        var disablesKeyboardSafeArea: Bool

        @available(iOS 14.0, *)
        var v2Body: some View {
            HostingRootView(content: content, transaction: transaction)
                .ignoresSafeArea(disablesKeyboardSafeArea ? .keyboard : [])
        }

        var v1Body: some View {
            HostingRootView(content: content, transaction: transaction)
        }
    }
}
#else
public typealias HostingControllerRootView<Content: View> = HostingRootView<Content>
#endif

open class HostingController<
    Content: View
>: PlatformHostingController<HostingControllerRootView<Content>> {

    public var content: Content {
        get { rootView.content }
        set { rootView.content = newValue }
    }

    #if os(watchOS)
    public var rootView: HostingRootView<Content> {
        didSet {
            setNeedsBodyUpdate()
        }
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 18.1, tvOS 18.1, visionOS 2.1, *)
    public var allowUIKitAnimations: Int32 {
        get { (view as! AnyHostingView).allowUIKitAnimations }
        set { (view as! AnyHostingView).allowUIKitAnimations = newValue }
    }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    public var allowUIKitAnimationsForNextUpdate: Bool {
        get { (view as! AnyHostingView).allowUIKitAnimationsForNextUpdate }
        set { (view as! AnyHostingView).allowUIKitAnimationsForNextUpdate = newValue }
    }

    @available(iOS 16.0, tvOS 16.0, *)
    public var automaticallyAllowUIKitAnimationsForNextUpdate: Bool {
        get { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate }
        set { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate = newValue }
    }
    private var shouldAutomaticallyAllowUIKitAnimationsForNextUpdate: Bool = true
    #endif

    #if os(iOS)
    @available(iOS 14.0, *)
    public var automaticallyDisableKeyboardSafeArea: Bool {
        get { shouldAutomaticallyDisableKeyboardSafeArea }
        set { shouldAutomaticallyDisableKeyboardSafeArea = newValue }
    }
    private var shouldAutomaticallyDisableKeyboardSafeArea = true {
        didSet {
            guard oldValue != shouldAutomaticallyDisableKeyboardSafeArea else { return }
            if shouldAutomaticallyDisableKeyboardSafeArea {
                if view.window != nil {
                    isObservingKeyboardNotifications = true
                    if !hasFirstResponder() {
                        isKeyboardSafeAreaDisabled = true
                    }
                }
            } else {
                isObservingKeyboardNotifications = false
                isKeyboardSafeAreaDisabled = false
            }
        }
    }

    private var isKeyboardSafeAreaDisabled: Bool = false {
        didSet {
            guard oldValue != isKeyboardSafeAreaDisabled else { return }
            isKeyboardSafeAreaDisabledDidChange()
        }
    }

    private var isObservingKeyboardNotifications: Bool = false {
        didSet {
            guard oldValue != isObservingKeyboardNotifications else { return }
            if isObservingKeyboardNotifications {
                registerForKeyboardNotifications()
            } else {
                unregisterForKeyboardNotifications()
            }
        }
    }
    #endif

    public init(content: Content) {
        let rootView = HostingControllerRootView(content: content, transaction: Transaction())
        #if os(watchOS)
        self.rootView = rootView
        super.init()
        #else
        super.init(rootView: rootView)
        #endif
    }

    #if !os(watchOS)
    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(tvOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(macOS, obsoleted: 10.15, renamed: "init(content:)")
    override init(rootView: HostingControllerRootView<Content>) {
        fatalError("init(rootView:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif

    open func update(content: Content, transaction: Transaction) {
        #if os(iOS)
        rootView = HostingControllerRootView(
            content: content,
            transaction: transaction,
            disablesKeyboardSafeArea: isKeyboardSafeAreaDisabled
        )
        #else
        rootView = HostingControllerRootView(
            content: content,
            transaction: transaction
        )
        #endif
        // Fixes `.transition` modifier
        if transaction.isAnimated {
            #if os(iOS) || os(tvOS) || os(visionOS)
            if transitionCoordinator == nil {
                view.layoutIfNeeded()
            }
            #elseif os(macOS)
            view.layoutSubtreeIfNeeded()
            #endif
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        if shouldRenderForContentUpdate {
            withCATransaction { [weak self] in
                self?.render()
            }
        }
        #endif
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    public func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
        let fittingSize = proposal
            .replacingUnspecifiedDimensions(
                by: CGSize(
                    width: CGFloat.infinity,
                    height: CGFloat.infinity
                )
            )
        let size = sizeThatFits(in: fittingSize)
        return size
    }
    #elseif os(macOS)
    public func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
        var sizeThatFits = view.fittingSize
        if let proposedWidth = proposal.width, proposedWidth != .infinity {
            sizeThatFits.width = max(sizeThatFits.width, proposedWidth)
        }
        if let proposedHeight = proposal.height, proposedHeight != .infinity {
            sizeThatFits.height = max(sizeThatFits.height, proposedHeight)
        }
        return sizeThatFits
    }
    #endif

    #if os(iOS)
    open override func viewDidLoad() {
        super.viewDidLoad()

        if shouldAutomaticallyDisableKeyboardSafeArea {
            isKeyboardSafeAreaDisabled = true
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldAutomaticallyDisableKeyboardSafeArea {
            isObservingKeyboardNotifications = true
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if shouldAutomaticallyDisableKeyboardSafeArea {
            isObservingKeyboardNotifications = false
            isKeyboardSafeAreaDisabled = true
        }
    }

    static var keyboardNotifications: [Notification.Name]  {
        if #available(iOS 14.0, *) {
            return [
                UIResponder.keyboardWillShowNotification,
                UIResponder.keyboardWillChangeFrameNotification,
                UIResponder.keyboardWillHideNotification,
                UIResponder.keyboardDidHideNotification,
            ]
        }
        return []
    }

    private func registerForKeyboardNotifications() {
        for name in Self.keyboardNotifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onKeyboardChange(_:)),
                name: name,
                object: nil
            )
        }
    }

    private func unregisterForKeyboardNotifications() {
        for name in Self.keyboardNotifications {
            NotificationCenter.default.removeObserver(
                self,
                name: name,
                object: nil
            )
        }
    }

    @objc
    private func onKeyboardChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool != false
        else {
            return
        }
        switch notification.name {
        case UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillChangeFrameNotification:
            if let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = view.window {
                let isVisible = endFrame.minY < window.bounds.height
                if isVisible {
                    enableKeyboardSafeAreaIfNeeded()
                } else {
                    isKeyboardSafeAreaDisabled = true
                }
            }
        case UIResponder.keyboardWillHideNotification, UIResponder.keyboardDidHideNotification:
            isKeyboardSafeAreaDisabled = true
        default:
            break
        }
    }

    private func enableKeyboardSafeAreaIfNeeded() {
        guard #available(iOS 14.0, *) else { return }
        guard isKeyboardSafeAreaDisabled, rootView.disablesKeyboardSafeArea else { return }
        if hasFirstResponder() {
            isKeyboardSafeAreaDisabled = false
        }
    }

    private func hasFirstResponder() -> Bool {
        guard presentedViewController == nil, let firstResponder = UIResponder.current else { return false }
        return firstResponder.isInResponderChain(of: self)
    }

    private func isKeyboardSafeAreaDisabledDidChange() {
        guard #available(iOS 14.0, *) else { return }
        rootView.disablesKeyboardSafeArea = isKeyboardSafeAreaDisabled
        view.layoutIfNeeded()
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    open override func viewWillLayoutSubviews() {
        if #available(iOS 16.0, tvOS 16.0, *), shouldAutomaticallyAllowUIKitAnimationsForNextUpdate {
            (view as! AnyHostingView).enableUIKitAnimationsIfNeeded()
        }
        super.viewWillLayoutSubviews()
    }
    #endif
}

#if !os(watchOS)
extension PlatformHostingController: AnyHostingController {

    #if os(iOS) || os(tvOS) || os(visionOS)
    public var disableSafeArea: Bool {
        get { _disableSafeArea }
        set { _disableSafeArea = newValue }
    }
    #endif

    public func render() {
        _render(seconds: 1 / 60)
    }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension AnyHostingController {

    public var shouldRenderForContentUpdate: Bool {
        if view.frame != .zero, transitionCoordinator == nil, view.window == nil {
            return true
        }
        return false
    }
}
#endif

#if os(iOS)
extension UIResponder {

    public func _isInResponderChain(of parent: UIResponder) -> Bool {
        isInResponderChain(of: parent)
    }

    func isInResponderChain(of parent: UIResponder) -> Bool {
        var responder: UIResponder? = self
        while let current = responder {
            if current === parent {
                return true
            }
            responder = current.next
        }
        return false
    }

    public static var _current: UIResponder? {
        current
    }

    static var current: UIResponder? {
        if lastCapturedFirstResponder?.isFirstResponder == true {
            return lastCapturedFirstResponder
        }
        UIApplication.shared.sendAction(
            #selector(UIResponder.captureCurrentFirstResponder(_:)),
            to: nil,
            from: nil,
            for: nil
        )
        return UIResponder.lastCapturedFirstResponder
    }

    @objc
    private func captureCurrentFirstResponder(_ sender: Any) {
        UIResponder.lastCapturedFirstResponder = self
    }

    private weak static var lastCapturedFirstResponder: UIResponder?
}
#endif
