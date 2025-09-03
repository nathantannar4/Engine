//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

#if os(macOS)
public typealias PlatformHostingView<Content: View> = NSHostingView<Content>
#else
public typealias PlatformHostingView<Content: View> = _UIHostingView<Content>
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
open class HostingView<
    Content: View
>: PlatformHostingView<Content> {

    public var content: Content {
        get {
            #if os(macOS)
            return rootView
            #else
            if #available(iOS 16.0, tvOS 16.0, *) {
                return rootView
            } else {
                do {
                    return try swift_getFieldValue("_rootView", Content.self, self)
                } catch {
                    fatalError("\(error)")
                }
            }
            #endif
        }
        set {
            #if os(macOS)
            rootView = newValue
            #else
            if #available(iOS 16.0, tvOS 16.0, *) {
                rootView = newValue
            } else {
                do {
                    var flags = try swift_getFieldValue("propertiesNeedingUpdate", UInt16.self, self)
                    try swift_setFieldValue("_rootView", newValue, self)
                    flags |= 1
                    try swift_setFieldValue("propertiesNeedingUpdate", flags, self)
                    setNeedsLayout()
                } catch {
                    fatalError("\(error)")
                }
            }
            #endif
        }
    }

    public var disablesSafeArea: Bool = false {
        didSet {
            guard oldValue != disablesSafeArea else { return }
            #if os(iOS) || os(tvOS) || os(visionOS)
            setNeedsLayout()
            #elseif os(macOS)
            needsLayout = true
            #endif
        }
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    public var allowUIKitAnimations: Int32 {
        get {
            let result = try? swift_getFieldValue("allowUIKitAnimations", Int32.self, self)
            return result ?? 0
        }
        set {
            try? swift_setFieldValue("allowUIKitAnimations", newValue, self)
        }
    }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    public var allowUIKitAnimationsForNextUpdate: Bool {
        get {
            let result = try? swift_getFieldValue("allowUIKitAnimationsForNextUpdate", Bool.self, self)
            return result ?? false
        }
        set {
            if #available(iOS 18.1, tvOS 18.1, *) {
                allowUIKitAnimations += 1
            } else {
                try? swift_setFieldValue("allowUIKitAnimationsForNextUpdate", newValue, self)
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

    #if os(macOS)
    @available(macOS 11.0, *)
    open override var safeAreaInsets: NSEdgeInsets {
        disablesSafeArea ? NSEdgeInsets() : super.safeAreaInsets
    }
    #else
    open override var safeAreaInsets: UIEdgeInsets {
        disablesSafeArea ? .zero : super.safeAreaInsets
    }
    #endif

    public init(content: Content) {
        super.init(rootView: content)
        #if os(macOS)
        layer?.backgroundColor = nil
        #else
        backgroundColor = nil
        #endif
        clipsToBounds = false
    }

    public convenience init(@ViewBuilder content: () -> Content) {
        self.init(content: content())
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(tvOS, obsoleted: 13.0, renamed: "init(content:)")
    @available(macOS, obsoleted: 10.15, renamed: "init(content:)")
    public required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    open override func layoutSubviews() {
        if #available(iOS 16.0, tvOS 16.0, *), shouldAutomaticallyAllowUIKitAnimationsForNextUpdate, 
            UIView.inheritedAnimationDuration > 0 || layer.animationKeys()?.isEmpty == false
        {
            if #available(iOS 18.1, tvOS 18.1, *) {
                allowUIKitAnimations += 1
            } else {
                allowUIKitAnimationsForNextUpdate = true
            }
        }
        super.layoutSubviews()
    }
    #endif

    #if os(macOS)
    open override func hitTest(_ point: NSPoint) -> NSView? {
        guard let result = super.hitTest(point), result != self else {
            return nil
        }
        return result
    }
    #else
    private var hitTestTimestamp: TimeInterval = 0
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if #available(iOS 26.0, *) {
            if result == self {
                // Hit testing on iOS 26 always returns self, so check the raw pixels to support passthrough
                let size = CGSize(width: 10, height: 10)
                UIGraphicsBeginImageContextWithOptions(size, false, window?.screen.scale ?? 1)
                defer { UIGraphicsEndImageContext() }
                guard let context = UIGraphicsGetCurrentContext() else {
                    return result
                }

                context.translateBy(x: -point.x + size.width / 2, y: -point.y + size.height / 2)
                layer.render(in: context)

                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                guard
                    let cgImage = image?.cgImage,
                    let data = cgImage.dataProvider?.data,
                    let ptr = CFDataGetBytePtr(data)
                else {
                    return result
                }

                let bytesPerPixel = 4
                let width = cgImage.width
                let height = cgImage.height

                for y in 0..<height {
                    for x in 0..<width {
                        let offset = (y * width + x) * bytesPerPixel
                        let alpha = ptr[offset + 3]
                        if alpha > 0 {
                            return result
                        }
                    }
                }
                return nil
            }
            return result
        } else if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            defer { hitTestTimestamp = event?.timestamp ?? 0 }
            if result == self, event?.timestamp != hitTestTimestamp {
                return nil
            }
            return result
        } else {
            if result == self {
                return nil
            }
            return result
        }
    }
    #endif
}

#endif // !os(watchOS)
