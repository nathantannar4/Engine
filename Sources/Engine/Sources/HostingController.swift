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

open class HostingController<
    Content: View
>: PlatformHostingController<HostingRootView<Content>> {

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

    public init(content: Content) {
        let rootView = HostingRootView(content: content, transaction: Transaction())
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
    override init(rootView: HostingRootView<Content>) {
        fatalError("init(rootView:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif

    open func update(content: Content, transaction: Transaction) {
        rootView = HostingRootView(
            content: content,
            transaction: transaction
        )
        // Fixes `.transition` modifier
        #if os(iOS) || os(tvOS) || os(visionOS)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        #elseif os(macOS)
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        #endif
        #if os(iOS)
        if shouldRenderForContentUpdate {
            withCATransaction {
                self._render(seconds: 1 / 60)
            }
        }
        #endif
    }

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

#if os(iOS)
extension AnyHostingController {

    public var shouldRenderForContentUpdate: Bool {
        if view.frame != .zero, transitionCoordinator == nil, view.window == nil {
            return true
        }
        return false
    }
}
#endif
