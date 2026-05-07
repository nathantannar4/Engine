//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

#if !os(watchOS)

#if os(macOS)
public typealias PlatformHostingView<Content: View> = NSHostingView<Content>
#else
public typealias PlatformHostingView<Content: View> = _UIHostingView<Content>
#endif

public protocol AnyHostingView: PlatformView {

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    var allowUIKitAnimations: Int32 { get set }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    @available(visionOS, introduced: 1.0, obsoleted: 2.1)
    var allowUIKitAnimationsForNextUpdate: Bool { get set }
    #endif

    func render()
}

open class HostingView<
    Content: View
>: PlatformHostingView<HostingRootView<Content>> {

    public var content: Content {
        get { _rootView.content }
        set { _rootView.content = newValue }
    }

    public var _rootView: HostingRootView<Content> {
        get {
            #if os(macOS)
            return rootView
            #else
            if #available(iOS 16.0, tvOS 16.0, *) {
                return rootView
            } else {
                do {
                    return try swift_getFieldValue("_rootView", HostingRootView<Content>.self, self)
                } catch {
                    os_log(.error, log: .default, "Failed to get `_rootView`. Please file an issue.")
                    fatalError(error.localizedDescription)
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
                    os_log(.error, log: .default, "Failed to set `_rootView`. Please file an issue.")
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
    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, *)
    public var automaticallyAllowUIKitAnimationsForNextUpdate: Bool {
        get { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate }
        set { shouldAutomaticallyAllowUIKitAnimationsForNextUpdate = newValue }
    }
    private var shouldAutomaticallyAllowUIKitAnimationsForNextUpdate: Bool = true
    #endif

    public var isHitTestingPassthrough: Bool = {
        if #available(iOS 26.0, *) {
            // iOS 26 changes hit testing making passthrough less reliable
            return false
        }
        return true
    }()

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
        let rootView = HostingRootView(content: content, transaction: Transaction())
        super.init(rootView: rootView)
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
    public required init(rootView: HostingRootView<Content>) {
        fatalError("init(rootView:) has not been implemented")
    }

    open func update(content: Content, transaction: Transaction) {
        _rootView = HostingRootView(
            content: content,
            transaction: transaction
        )
        // Fixes `.transition` modifier
        #if os(iOS) || os(tvOS) || os(visionOS)
        setNeedsLayout()
        layoutIfNeeded()
        #elseif os(macOS)
        needsLayout = true
        layout()
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
        let size = sizeThatFits(fittingSize)
        return size
    }
    #elseif os(macOS)
    public func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
        var sizeThatFits = fittingSize
        if let proposedWidth = proposal.width, proposedWidth != .infinity {
            sizeThatFits.width = max(sizeThatFits.width, proposedWidth)
        }
        if let proposedHeight = proposal.height, proposedHeight != .infinity {
            sizeThatFits.height = max(sizeThatFits.height, proposedHeight)
        }
        return sizeThatFits
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    open override func layoutSubviews() {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, *), shouldAutomaticallyAllowUIKitAnimationsForNextUpdate {
            enableUIKitAnimationsIfNeeded()
        }
        super.layoutSubviews()
    }
    #endif

    #if os(macOS)
    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result == self, isHitTestingPassthrough {
            return nil
        }
        return result
    }
    #else
    struct HitTestEvent {
        var point: CGPoint
        var timestamp: TimeInterval
    }
    private var lastHitTestEvent: HitTestEvent?
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if #available(iOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            // Hit testing on iOS 26 always seems to return self
            if result == self, isHitTestingPassthrough {
                // Hit test the layers
                for sublayer in layer.sublayers ?? [] {
                    if !sublayer.isHidden, sublayer.frame.contains(point) {
                        return result
                    }
                }

                #if os(iOS) || os(tvOS) || os(visionOS)
                // Check the raw pixels to support passthrough
                let size = CGSize(width: 10, height: 10)
                UIGraphicsBeginImageContextWithOptions(size, false, traitCollection.displayScale)
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
                #endif
                return nil
            }
            return result
        } else if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            defer {
                lastHitTestEvent = event.map {
                    HitTestEvent(
                        point: point,
                        timestamp: $0.timestamp
                    )
                }
            }
            if result == self, isHitTestingPassthrough,
                lastHitTestEvent?.timestamp != event?.timestamp || lastHitTestEvent?.point.rounded() != point.rounded()
            {
                return nil
            }
            return result
        } else {
            if result == self, isHitTestingPassthrough {
                return nil
            }
            return result
        }
    }
    #endif
}

extension PlatformHostingView: AnyHostingView {

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    public var allowUIKitAnimations: Int32 {
        get {
            do {
                return try swift_getFieldValue("allowUIKitAnimations", Int32.self, self)
            } catch {
                os_log(.error, log: .default, "Failed to get `allowUIKitAnimations`. Please file an issue.")
                return 0
            }
        }
        set {
            do {
                try swift_setFieldValue("allowUIKitAnimations", newValue, self)
            } catch {
                os_log(.error, log: .default, "Failed to set `allowUIKitAnimations`. Please file an issue.")
            }
        }
    }

    @available(iOS, introduced: 16.0, obsoleted: 18.1)
    @available(tvOS, introduced: 16.0, obsoleted: 18.1)
    @available(visionOS, introduced: 1.0, obsoleted: 2.1)
    public var allowUIKitAnimationsForNextUpdate: Bool {
        get {
            do {
                return try swift_getFieldValue("allowUIKitAnimationsForNextUpdate", Bool.self, self)
            } catch {
                os_log(.error, log: .default, "Failed to get `allowUIKitAnimationsForNextUpdate`. Please file an issue.")
                return false
            }
        }
        set {
            if #available(iOS 18.1, tvOS 18.1, visionOS 2.1, *) {
                if newValue {
                    allowUIKitAnimations += 1
                }
            } else {
                do {
                    try swift_setFieldValue("allowUIKitAnimationsForNextUpdate", newValue, self)
                } catch {
                    os_log(.error, log: .default, "Failed to set `allowUIKitAnimationsForNextUpdate`. Please file an issue.")
                }
            }
        }
    }
    #endif

    public func render() {
        _renderForTest(interval: 1 / 60)
    }
}

extension AnyHostingView {

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, *)
    func enableUIKitAnimationsIfNeeded() {
        if UIView.inheritedAnimationDuration > 0 || layer.animationKeys()?.isEmpty == false {
            enableUIKitAnimations()
        }
    }

    @available(iOS 16.0, tvOS 16.0, visionOS 1.0, *)
    private func enableUIKitAnimations() {
        func enableUIKitAnimations(hostingView: AnyHostingView) {
            if #available(iOS 18.1, tvOS 18.1, visionOS 2.1, *) {
                hostingView.allowUIKitAnimations += 1
            } else {
                hostingView.allowUIKitAnimationsForNextUpdate = true
            }
        }
        func enableUIKitAnimations(subviews: [UIView]) {
            for subview in subviews {
                if let hostingView = subview as? AnyHostingView {
                    hostingView.enableUIKitAnimationsIfNeeded()
                } else {
                    enableUIKitAnimations(subviews: subview.subviews)
                }
            }
        }
        enableUIKitAnimations(hostingView: self)
        enableUIKitAnimations(subviews: subviews)
    }
    #endif
}

#if os(iOS) || os(tvOS) || os(visionOS)
fileprivate extension CGPoint {
    func rounded() -> CGPoint {
        CGPoint(x: x.rounded(), y: y.rounded())
    }
}
#endif

// MARK: - Previews

struct HostingView_Previews: PreviewProvider {

    #if os(iOS) || os(tvOS) || os(visionOS)
    struct HostingViewAdapter<
        Content: View
    >: UIViewRepresentable {

        var content: Content

        typealias UIViewType = HostingView<Content>

        init(
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
        }

        func makeUIView(context: Context) -> UIViewType {
            let uiView = HostingView(content: content)
            return uiView
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {
            uiView.update(content: content, transaction: context.transaction)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        func sizeThatFits(
            _ proposal: ProposedViewSize,
            uiView: UIViewType,
            context: Context
        ) -> CGSize? {
            return uiView.sizeThatFits(ProposedSize(proposal))
        }

        func _overrideSizeThatFits(
            _ size: inout CGSize,
            in proposedSize: _ProposedSize,
            uiView: UIViewType
        ) {
            size = uiView.sizeThatFits(ProposedSize(proposedSize))
        }
    }
    #else
    struct HostingViewAdapter<
        Content: View
    >: NSViewRepresentable {

        var content: Content

        typealias NSViewType = HostingView<Content>

        init(
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
        }

        func makeNSView(context: Context) -> NSViewType {
            let nsView = HostingView(content: content)
            return nsView
        }

        func updateNSView(_ nsView: NSViewType, context: Context) {
            nsView.update(content: content, transaction: context.transaction)
        }

        @available(macOS 13.0, *)
        func sizeThatFits(
            _ proposal: ProposedViewSize,
            nsView: NSViewType,
            context: Context
        ) -> CGSize? {
            return nsView.sizeThatFits(ProposedSize(proposal))
        }

        func _overrideSizeThatFits(
            _ size: inout CGSize,
            in proposedSize: _ProposedSize,
            nsView: NSViewType
        ) {
            size = nsView.sizeThatFits(ProposedSize(proposedSize))
        }
    }
    #endif

    struct Preview: View {
        var body: some View {
            VStack {
                StateAdapter(initialValue: false) { $isExpanded in
                    VStack {
                        HostingViewAdapter {
                            Content(isExpanded: isExpanded)
                        }

                        Button {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        } label: {
                            Text("Toggle")
                        }
                    }
                    .padding()
                    .border(Color.red)
                }

                HostingViewAdapter {
                    StateAdapter(initialValue: false) { $isExpanded in
                        VStack {
                            Content(isExpanded: isExpanded)

                            Button {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            } label: {
                                Text("Toggle")
                            }
                        }
                        .padding()
                        .border(Color.red)
                    }
                }
            }
        }

        struct Content: View {
            var isExpanded: Bool

            var body: some View {
                VStack {
                    Text("Title")

                    if isExpanded {
                        Text("Subtitle")
                            .transition(.scale)
                    }
                }
                .frame(maxWidth: isExpanded ? .infinity : nil)
                .padding()
                .border(Color.red)
            }
        }
    }

    static var previews: some View {
        ZStack {
            Preview()
        }

        VStack {
            HostingViewAdapter {
                Text("Hello, World")
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
            }
            .padding()
            .background(Color.red)

            ScrollView {
                HostingViewAdapter {
                    Text("Hello, World")
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                }
                .padding()
                .background(Color.red)
            }
        }
        .frame(width: 300, height: 300)
        .previewLayout(.sizeThatFits)

        VStack {
            HostingViewAdapter {
                Text("Hello, World")
                    .background(Color.yellow)
            }
            .padding()
            .background(Color.red)

            ScrollView {
                HostingViewAdapter {
                    Text("Hello, World")
                        .background(Color.yellow)
                }
                .padding()
                .background(Color.red)
            }
        }
        .frame(width: 300, height: 300)
        .previewLayout(.sizeThatFits)

        HostingViewAdapter {
            Color.yellow
        }
        .frame(width: 300, height: 300)
        .previewLayout(.sizeThatFits)
    }
}

#endif
