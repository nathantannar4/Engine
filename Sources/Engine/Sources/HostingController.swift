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

    public var disablesSafeArea: Bool {
        get {
            if #available(macOS 13.3, iOS 16.4, tvOS 16.4, *) {
                return safeAreaRegions.isEmpty
            } else {
                #if os(iOS) || os(tvOS)
                return _disableSafeArea
                #else
                return false
                #endif
            }
        }
        set {
            if #available(macOS 13.3, iOS 16.4, tvOS 16.4, *) {
                safeAreaRegions = newValue ? [] : .all
            } else {
                #if os(iOS) || os(tvOS)
                _disableSafeArea = newValue
                #endif
            }
        }
    }

    #if os(iOS) || os(tvOS)
    @available(iOS 16.0, tvOS 16.0, *)
    public var allowUIKitAnimations: Int32 {
        get {
            guard let view else { return 0 }
            let result = try? swift_getFieldValue("allowUIKitAnimations", Int32.self, view)
            return result ?? 0
        }
        set {
            guard let view else { return }
            try? swift_setFieldValue("allowUIKitAnimations", newValue, view)
        }
    }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    public var allowUIKitAnimationsForNextUpdate: Bool {
        get {
            guard let view else { return false }
            let result = try? swift_getFieldValue("allowUIKitAnimationsForNextUpdate", Bool.self, view)
            return result ?? false
        }
        set {
            guard let view else { return }
            try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", newValue, view)
        }
    }

    @available(iOS 16.0, tvOS 16.0, *)
    public var automaticallyAllowUIKitAnimationsForNextUpdate: Bool {
        get { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate }
        set { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate = newValue }
    }
    private var shouldAutomaticallyAllowUIKitAnimationsForNextUpdate: Bool = true
    #endif

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

    #if os(iOS) || os(tvOS)
    open override func viewWillLayoutSubviews() {
        if #available(iOS 16.0, tvOS 16.0, *), shouldAutomaticallyAllowUIKitAnimationsForNextUpdate,
            UIView.inheritedAnimationDuration > 0 || view.layer.animationKeys()?.isEmpty == false
        {
            if #available(iOS 18.1, tvOS 18.1, *) {
                allowUIKitAnimations += 1
            } else {
                allowUIKitAnimationsForNextUpdate = true
            }
        }
        super.viewWillLayoutSubviews()
    }
    #endif
}

#endif // !os(watchOS)
