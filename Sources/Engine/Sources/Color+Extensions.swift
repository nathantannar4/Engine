//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

extension Color {

    /// Transforms SwiftUI `Color` to a non-bridged `CGColor`
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func toCGColor(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> CGColor {
        if let cgColor = cgColor {
            return cgColor
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *), let environment = environment() {
            return resolve(in: environment).cgColor
        } else {
            return toPlatformValue(in: environment()).cgColor
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `Color` to a non-bridged `UIColor`
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func toUIColor(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> UIColor {
        toPlatformValue(in: environment())
    }
    #endif

    #if os(macOS)
    /// Transforms SwiftUI `Color` to a non-bridged `NSColor`
    @available(macOS 11.0, *)
    public func toNSColor(
        in environment: @autoclosure () -> EnvironmentValues? = nil
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
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> PlatformRepresentable {
        func resolve(provider: Any) -> PlatformRepresentable {
            if let color = provider as? PlatformRepresentable {
                return color
            }

            let className = String(describing: type(of: provider))
            switch className {
            case "OpacityColor":
                guard
                    let opacity = try? swift_getFieldValue("opacity", Double.self, provider),
                    let base = try? swift_getFieldValue("base", Any.self, provider)
                else {
                    return .resolved(self, in: environment())
                }
                let color = resolve(provider: base)
                return color.withAlphaComponent(opacity)

            case "NamedColor":
                guard
                    let name = try? swift_getFieldValue("name", String.self, provider)
                else {
                    return .resolved(self, in: environment())
                }
                let bundle = try? swift_getFieldValue("bundle", Bundle.self, provider)
                #if os(iOS) || os(tvOS) || os(visionOS)
                return UIColor { traits in
                    UIColor(named: name, in: bundle, compatibleWith: traits) ?? UIColor(self)
                }
                #elseif os(watchOS)
                return UIColor(named: name) ?? .resolved(self, in: environment())
                #else
                return NSColor(named: name, bundle: bundle) ?? .resolved(self, in: environment())
                #endif

            case "Color", "SystemColorType", "ResolvedColorProvider":
                if self == .clear {
                    return .clear
                }
                if self == .white {
                    return .white
                }
                if self == .black {
                    return .black
                }
                return .resolved(self, in: environment())

            case "UIKitPlatformColorProvider", "AppKitPlatformColorProvider":
                guard
                    let color = try? swift_getFieldValue("platformColor", PlatformRepresentable.self, provider)
                else {
                    return .resolved(self, in: environment())
                }
                return color

            default:
                os_log(.error, log: .default, "Failed to resolve Color provider %{public}@. Please file an issue.", className)
                return .resolved(self, in: environment())
            }
        }

        // Need to extract the UIColor since because SwiftUI's UIColor init
        // from a Color does not work for dynamic colors when set on UIView's
        guard
            let provider = try? swift_getFieldValue("provider", Any.self, self),
            let base = try? swift_getFieldValue("base", Any.self, provider)
        else {
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
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> Color.PlatformRepresentable {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *), let environment = environment() {
            return UIColor { [environment] traitCollection in
                var environment = environment
                if let colorScheme = ColorScheme(traitCollection.userInterfaceStyle) {
                    environment.colorScheme = colorScheme
                }
                if let colorSchemeContrast = ColorSchemeContrast(traitCollection.accessibilityContrast) {
                    environment._colorSchemeContrast = colorSchemeContrast
                }
                let cgColor = color.resolve(in: environment).cgColor
                return UIColor(cgColor: cgColor)
            }
        }
        return UIColor(color)
        #elseif os(watchOS)
        return UIColor(color)
        #else
        return NSColor(color)
        #endif
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Color_Previews: PreviewProvider {
    struct ColorPreview: View {
        var color: Color

        @Environment(\.self) var environment

        var body: some View {
            HStack(spacing: 4) {
                color
                #if os(macOS)
                Color(nsColor: color.toNSColor())
                Color(nsColor: color.toNSColor(in: environment))
                #else
                Color(uiColor: color.toUIColor())
                Color(uiColor: color.toUIColor(in: environment))
                #endif
            }
            .frame(height: 20)
        }
    }

    static var previews: some View {
        VStack(spacing: 4) {
            ColorPreview(color: .blue)
            ColorPreview(color: .blue.opacity(0.3))
            ColorPreview(color: Color(cgColor: .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)))
            ColorPreview(color: Color("Named", bundle: .main))
            #if os(macOS)
            ColorPreview(color: Color(nsColor: .systemBlue))
            ColorPreview(color: Color(nsColor: .systemBlue.withAlphaComponent(0.3)))
            ColorPreview(color: Color(nsColor: .systemBlue).opacity(0.3))
            #elseif !os(watchOS)
            ColorPreview(color: Color(uiColor: .systemBlue))
            ColorPreview(color: Color(uiColor: .systemBlue.withAlphaComponent(0.3)))
            ColorPreview(color: Color(uiColor: .systemBlue).opacity(0.3))
            ColorPreview(color: Color(uiColor: UIColor(dynamicProvider: { traits in
                return .gray.withAlphaComponent(traits.userInterfaceStyle == .light ? 0.8 : 0.2)
            })))
            .environment(\.colorScheme, .light)
            ColorPreview(color: Color(uiColor: UIColor(dynamicProvider: { traits in
                return .gray.withAlphaComponent(traits.userInterfaceStyle == .light ? 0.8 : 0.2)
            })))
            .environment(\.colorScheme, .dark)
            #endif
        }
    }
}
