//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

#if os(macOS)
public typealias PlatformHostingController<Content: View> = NSHostingController<Content>
#else
public typealias PlatformHostingController<Content: View> = UIHostingController<Content>
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
open class HostingController<
    Content: View
>: PlatformHostingController<Content> {

    public var content: Content {
        get { rootView }
        set { rootView = newValue }
    }

    @available(macOS 13.3, iOS 13.0, tvOS 13.0, *)
    public var disablesSafeArea: Bool {
        get {
            #if os(iOS) || os(tvOS)
            return _disableSafeArea
            #else
            return safeAreaRegions.isEmpty
            #endif
        }
        set {
            if #available(iOS 16.4, tvOS 16.4, *) {
                safeAreaRegions = newValue ? [] : .all
            }
            #if os(iOS) || os(tvOS)
            _disableSafeArea = newValue
            #endif
        }
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 18.1, tvOS 18.1, visionOS 2.1, *)
    public var allowUIKitAnimations: Int32 {
        get {
            guard let view else { return 0 }
            let result = try? swift_getFieldValue("allowUIKitAnimations", Int32.self, view)
            return result ?? 0
        }
        set {
            guard let view else { return }
            do {
                try swift_setFieldValue("allowUIKitAnimations", newValue, view)
            } catch {
                print("Failed to set `allowUIKitAnimations`, this is unexpected please file an issue =")
            }
        }
    }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    public var allowUIKitAnimationsForNextUpdate: Bool {
        get {
            if #available(iOS 18.1, tvOS 18.1, visionOS 2.1, *) {
                return allowUIKitAnimations > 0
            } else {
                guard let view else { return false }
                let result = try? swift_getFieldValue("allowUIKitAnimationsForNextUpdate", Bool.self, view)
                return result ?? false
            }
        }
        set {
            if #available(iOS 18.1, tvOS 18.1, visionOS 2.1, *) {
                allowUIKitAnimations += 1
            } else {
                guard let view else { return }
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", newValue, view)
            }
        }
    }

    @available(iOS 16.0, tvOS 16.0, *)
    public var automaticallyAllowUIKitAnimationsForNextUpdate: Bool {
        get { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate }
        set { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate = newValue }
    }
    private var shouldAutomaticallyAllowUIKitAnimationsForNextUpdate: Bool = true
    #endif

    /// The pending transaction that was used to trigger a content update
    public private(set) var transaction: Transaction?

    public init(content: Content) {
        super.init(rootView: content)
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(tvOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(macOS, obsoleted: 10.15, renamed: "init(content:)")
    override init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        self.content = content
        self.transaction = transaction
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    open override func viewWillLayoutSubviews() {
        if #available(iOS 16.0, tvOS 16.0, *), shouldAutomaticallyAllowUIKitAnimationsForNextUpdate,
            UIView.inheritedAnimationDuration > 0 || view.layer.animationKeys()?.isEmpty == false
        {
            if children.count > 0 {
                prepareForUIKitAnimations()
            } else {
                if #available(iOS 18.1, tvOS 18.1, visionOS 2.1, *) {
                    allowUIKitAnimations += 1
                } else {
                    allowUIKitAnimationsForNextUpdate = true
                }
            }
        }
        super.viewWillLayoutSubviews()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        transaction = nil
    }
    #elseif os(macOS)
    open override func viewDidLayout() {
        super.viewDidLayout()
        transaction = nil
    }
    #endif
}

#if os(iOS) || os(tvOS) || os(visionOS)
protocol _UIHostingViewType { }
extension _UIHostingView: _UIHostingViewType { }

extension UIViewController {
    func prepareForUIKitAnimations() {
        guard let view else { return }
        if view is _UIHostingViewType {
            do {
                if #available(iOS 18.1, tvOS 18.1, *) {
                    var allowUIKitAnimations = try swift_getFieldValue("allowUIKitAnimations", Int32.self, view)
                    allowUIKitAnimations += 1
                    try swift_setFieldValue("allowUIKitAnimations", allowUIKitAnimations, view)
                } else {
                    try swift_setFieldValue("allowUIKitAnimationsForNextUpdate", true, view)
                }
            } catch {
                print("Failed to allow UIKit animations, this is unexpected please file an issue =")
            }
        }
        for child in children {
            child.prepareForUIKitAnimations()
        }
    }
}
#endif
#endif // !os(watchOS)
