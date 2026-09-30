//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

#if os(macOS)
/// The platform view type, `UIView` or `NSView`.
public typealias PlatformView = NSView
/// The platform view representable protocol, `UIViewRepresentable` or `NSViewRepresentable`.
public typealias PlatformViewRepresentable = NSViewRepresentable
/// The platform view controller representable protocol, `UIViewControllerRepresentable` or `NSViewControllerRepresentable`.
public typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
/// The ``TypeDescriptor`` for the platform view representable protocol.
public typealias PlatformViewRepresentableProtocolDescriptor = NSViewRepresentableProtocolDescriptor
/// The ``TypeDescriptor`` for the platform view controller representable protocol.
public typealias PlatformViewControllerRepresentableProtocolDescriptor = NSViewControllerRepresentableProtocolDescriptor
/// The platform view controller type, `UIViewController` or `NSViewController`.
public typealias PlatformViewController = NSViewController
extension PlatformViewControllerRepresentable {
    /// The type of view controller to present.
    public typealias PlatformViewControllerType = NSViewControllerType
}
#else
/// The platform view type, `UIView` or `NSView`.
public typealias PlatformView = UIView
/// The platform view representable protocol, `UIViewRepresentable` or `NSViewRepresentable`.
public typealias PlatformViewRepresentable = UIViewRepresentable
/// The platform view controller representable protocol, `UIViewControllerRepresentable` or `NSViewControllerRepresentable`.
public typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
/// The ``TypeDescriptor`` for the platform view representable protocol.
public typealias PlatformViewRepresentableProtocolDescriptor = UIViewRepresentableProtocolDescriptor
/// The ``TypeDescriptor`` for the platform view controller representable protocol.
public typealias PlatformViewControllerRepresentableProtocolDescriptor = UIViewControllerRepresentableProtocolDescriptor
/// The platform view controller type, `UIViewController` or `NSViewController`.
public typealias PlatformViewController = UIViewController
extension UIViewControllerRepresentable {
    /// The type of view controller to present.
    public typealias PlatformViewControllerType = UIViewControllerType
}
#endif

#endif
