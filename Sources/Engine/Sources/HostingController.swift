//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI

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
    var transaction: Transaction? { get }
    func render()
}
#endif

open class HostingController<
    Content: View
>: PlatformHostingController<Content> {

    public var content: Content {
        get { rootView }
        set { rootView = newValue }
    }

    #if os(watchOS)
    public var rootView: Content {
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

    /// The pending transaction that was used to trigger a content update
    fileprivate var updateTransaction: Transaction?

    public init(content: Content) {
        #if os(watchOS)
        self.rootView = content
        super.init()
        #else
        super.init(rootView: content)
        #endif
    }

    #if !os(watchOS)
    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(tvOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(macOS, obsoleted: 10.15, renamed: "init(content:)")
    override init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif

    open func update(content: Content, transaction: Transaction) {
        self.content = content
        self.updateTransaction = transaction
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

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTransaction = nil
    }
    #elseif os(macOS)
    open override func viewDidLayout() {
        super.viewDidLayout()
        updateTransaction = nil
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

    public var transaction: Transaction? {
        if let hostingController = self as? HostingController<Content> {
            return hostingController.updateTransaction
        }
        return nil
    }

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
