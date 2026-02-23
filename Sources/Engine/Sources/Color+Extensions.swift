//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

extension Color {

    /// Transforms SwiftUI `Color` to a non-bridged `CGColor`
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func toCGColor(
        in environment: @autoclosure () -> EnvironmentValues = EnvironmentValues()
    ) -> CGColor {
        if let cgColor = cgColor {
            return cgColor
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            return resolve(in: environment()).cgColor
        } else {
            return toPlatformValue(in: environment()).cgColor
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `Color` to a non-bridged `UIColor`
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func toUIColor(
        in environment: @autoclosure () -> EnvironmentValues = EnvironmentValues()
    ) -> UIColor {
        toPlatformValue(in: environment())
    }
    #endif

    #if os(macOS)
    /// Transforms SwiftUI `Color` to a non-bridged `NSColor`
    @available(macOS 11.0, *)
    public func toNSColor(
        in environment: @autoclosure () -> EnvironmentValues = EnvironmentValues()
    ) -> NSColor {
        toPlatformValue(in: environment())
    }
    #endif

    #if os(macOS)
    typealias PlatformRepresentable = NSColor
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIColor
    #endif
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `Color` to a non-bridged color
    ///
    /// > Important: Using the built in `UIColor(_ color: Color)`/`NSColor(_ color: Color)`
    /// results in a bridged color which can sometimes fail to render correctly for the appropriate
    /// light/dark appearance.
    ///
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func toPlatformValue(
        in environment: @autoclosure () -> EnvironmentValues = EnvironmentValues()
    ) -> PlatformRepresentable {
        func resolve(provider: Any) -> PlatformRepresentable {
            let className = String(describing: type(of: provider))
            switch className {
            case "OpacityColor":
                let mirror = Mirror(reflecting: provider)
                guard
                    let opacity = mirror.descendant("opacity") as? Double,
                    let base = mirror.descendant("base")
                else {
                    return .resolved(self, in: environment())
                }
                let color = resolve(provider: base)
                return color.withAlphaComponent(opacity)

            case "NamedColor":
                let mirror = Mirror(reflecting: provider)
                guard
                    let name = mirror.descendant("name") as? String
                else {
                    return .resolved(self, in: environment())
                }
                let bundle = mirror.descendant("bundle") as? Bundle
                #if os(iOS) || os(tvOS) || os(visionOS)
                return UIColor { traits in
                    UIColor(named: name, in: bundle, compatibleWith: traits) ?? UIColor(self)
                }
                #elseif os(watchOS)
                return UIColor(named: name) ?? .resolved(self, in: environment())
                #else
                return NSColor(named: name, bundle: bundle) ?? .resolved(self, in: environment())
                #endif
            default:
                if let color = provider as? PlatformRepresentable {
                    return color
                }
                os_log(.error, log: .default, "Failed to resolve Color provider %{public}@. Please file an issue.", className)
                return .resolved(self, in: environment())
            }
        }

        // Need to extract the UIColor since because SwiftUI's UIColor init
        // from a Color does not work for dynamic colors when set on UIView's
        guard let base = Mirror(reflecting: self).descendant("provider", "base") else {
            return .resolved(self, in: environment())
        }
        return resolve(provider: base)
    }
    #endif
}

extension Color.PlatformRepresentable {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    static func resolved(
        _ color: Color,
        in environment: @autoclosure () -> EnvironmentValues = EnvironmentValues()
    ) -> Color.PlatformRepresentable {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIColor { [environment = environment()] traitCollection in
            var environment = environment
            if let colorScheme = ColorScheme(traitCollection.userInterfaceStyle) {
                environment.colorScheme = colorScheme
            }
            if let colorSchemeContrast = ColorSchemeContrast(traitCollection.accessibilityContrast) {
                environment._colorSchemeContrast = colorSchemeContrast
            }
            let resolved = color.toCGColor(in: environment)
            return UIColor(cgColor: resolved)
        }
        #elseif os(watchOS)
        return UIColor(color)
        #else
        return NSColor(color)
        #endif
    }
}
