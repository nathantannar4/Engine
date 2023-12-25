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
            if #available(macOS 13.3, iOS 16.4, *) {
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
            if #available(macOS 13.3, iOS 16.4, *) {
                safeAreaRegions = newValue ? [] : .all
            } else {
                #if os(iOS) || os(tvOS)
                _disableSafeArea = newValue
                #endif
            }
        }
    }

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
}

#endif // !os(watchOS)
