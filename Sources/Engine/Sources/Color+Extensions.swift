//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Color {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func toCGColor() -> CGColor {
        if let cgColor = cgColor {
            return cgColor
        } else {
            return PlatformRepresentable(self).cgColor
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func toUIColor() -> UIColor {
        toPlatformValue()
    }
    #endif

    #if os(macOS)
    @available(macOS 11.0, *)
    public func toNSColor() -> NSColor {
        toPlatformValue()
    }
    #endif

    #if os(macOS)
    typealias PlatformRepresentable = NSColor
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIColor
    #endif
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    private func toPlatformValue() -> PlatformRepresentable {
        func resolve(provider: Any) -> PlatformRepresentable {
            let className = String(describing: type(of: provider))
            switch className {
            case "OpacityColor":
                let mirror = Mirror(reflecting: provider)
                guard
                    let opacity = mirror.descendant("opacity") as? Double,
                    let base = mirror.descendant("base")
                else {
                    return PlatformRepresentable(self)
                }
                let color = resolve(provider: base)
                return color.withAlphaComponent(opacity)

            case "NamedColor":
                let mirror = Mirror(reflecting: provider)
                guard
                    let name = mirror.descendant("name") as? String
                else {
                    return PlatformRepresentable(self)
                }
                let bundle = mirror.descendant("bundle") as? Bundle
                #if os(iOS) || os(tvOS) || os(visionOS)
                return UIColor { traits in
                    UIColor(named: name, in: bundle, compatibleWith: traits) ?? UIColor(self)
                }
                #elseif os(watchOS)
                return UIColor(named: name) ?? UIColor(self)
                #else
                return NSColor(named: name, bundle: bundle) ?? NSColor(self)
                #endif
            default:
                return provider as? PlatformRepresentable ?? PlatformRepresentable(self)
            }
        }

        // Need to extract the UIColor since because SwiftUI's UIColor init
        // from a Color does not work for dynamic colors when set on UIView's
        guard let base = Mirror(reflecting: self).descendant("provider", "base") else {
            return PlatformRepresentable(self)
        }
        return resolve(provider: base)
    }
    #endif
}
