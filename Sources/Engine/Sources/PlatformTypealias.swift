//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

#if os(macOS)
public typealias PlatformView = NSView
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
public typealias PlatformViewControllerRepresentableProtocolDescriptor = NSViewControllerRepresentableProtocolDescriptor
public typealias PlatformViewController = NSViewController
extension PlatformViewControllerRepresentable {
    public typealias PlatformViewControllerType = NSViewControllerType
}
#else
public typealias PlatformView = UIView
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
public typealias PlatformViewControllerRepresentableProtocolDescriptor = UIViewControllerRepresentableProtocolDescriptor
public typealias PlatformViewController = UIViewController
extension UIViewControllerRepresentable {
    public typealias PlatformViewControllerType = UIViewControllerType
}
#endif

#endif
