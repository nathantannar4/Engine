//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AnyShapeStyle {

    @frozen
    public struct ResolvedStyle: Sendable {
        @frozen
        public indirect enum Kind: Sendable {
            case color(Color)
            case material(Material)
            @frozen
            public enum HierarchicalLevel: Int, Sendable {
                case primary = 0
                case secondary
                case tertiary
                case quaternary
                case quinary

                var opacity: Double {
                    switch self {
                    case .primary:
                        return 1
                    case .secondary:
                        return 0.5
                    case .tertiary:
                        return 0.25
                    case .quaternary, .quinary:
                        return 0.18
                    }
                }
            }
            case hierarchical(HierarchicalLevel, ResolvedStyle.Kind?)
            case foreground
            case background
            case selection
            case separator
            case tint
            case placeholder
            case link
            case fill
            case windowBackground

            func color(in environment: EnvironmentValues) -> Color? {
                switch self {
                case .color(let color):
                    return color

                case .hierarchical(let level, let kind):
                    if level == .secondary, case .color(let color) = kind, color == .primary {
                        return .secondary
                    }
                    return kind?.color(in: environment)?.opacity(level.opacity)

                case .tint:
                    if let resolvedTint = environment.tint.resolve(in: environment) {
                        if case .tint = resolvedTint.kind {
                            return nil
                        }
                        return resolvedTint.kind.color(in: environment)?.opacity(resolvedTint.opacity)
                    }
                    return nil

                case .foreground:
                    if let resolvedForeground = environment.foregroundStyle.resolve(in: environment) {
                        if case .foreground = resolvedForeground.kind {
                            return nil
                        }
                        return resolvedForeground.kind.color(in: environment)?.opacity(resolvedForeground.opacity)
                    }
                    return nil

                case .background:
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                        let resolvedBackground = environment.backgroundStyle?.resolve(in: environment)
                    {
                        if case .background = resolvedBackground.kind {
                            return nil
                        }
                        return resolvedBackground.kind.color(in: environment)?.opacity(resolvedBackground.opacity)
                    }
                    return nil

                default:
                    return nil
                }
            }
        }
        public var kind: Kind
        public var opacity: Double = 1
        public var blendMode: BlendMode = .normal
    }

    public func color(in environment: EnvironmentValues) -> Color? {
        guard
            let style = resolve(in: environment),
            let color = style.kind.color(in: environment)
        else {
            return nil
        }
        return color.opacity(style.opacity)
    }

    public func resolve(in environment: EnvironmentValues) -> ResolvedStyle? {
        func resolve(provider: Any) -> ResolvedStyle? {
            let className = String(describing: type(of: provider))
            if className == "AnyShapeStyle" {
                let mirror = Mirror(reflecting: provider)
                if let provider = mirror.descendant("storage", "box") {
                    return resolve(provider: provider)
                }
            } else if className == "Color", let color = provider as? Color {
                return ResolvedStyle(kind: .color(color))
            } else if className == "Material", let material = provider as? Material {
                return ResolvedStyle(kind: .material(material))
            } else if className.hasPrefix("ColorBox") {
                let color = unsafeBitCast(provider as AnyObject, to: Color.self)
                return ResolvedStyle(kind: .color(color))
            } else if className == "AnyGradient" {
                let mirror = Mirror(reflecting: provider)
                if let provider = mirror.descendant("provider") {
                    return resolve(provider: provider)
                }
            } else if className.hasPrefix("GradientBox") {
                let mirror = Mirror(reflecting: provider)
                if let provider = mirror.descendant("base", "color", "provider") {
                    return resolve(provider: provider)
                }
            } else if className == "ForegroundStyle" {
                return ResolvedStyle(kind: .foreground)
            } else if className == "BackgroundStyle" {
                return ResolvedStyle(kind: .background)
            } else if className == "SelectionShapeStyle" {
                return ResolvedStyle(kind: .selection)
            } else if className == "SeparatorShapeStyle" {
                return ResolvedStyle(kind: .separator)
            } else if className == "TintShapeStyle" {
                return ResolvedStyle(kind: .tint)
            } else if className == "PlaceholderTextShapeStyle" {
                return ResolvedStyle(kind: .placeholder)
            } else if className == "LinkShapeStyle" {
                return ResolvedStyle(kind: .link)
            } else if className == "FillShapeStyle" {
                return ResolvedStyle(kind: .fill)
            } else if className == "WindowBackgroundShapeStyle" {
                return ResolvedStyle(kind: .windowBackground)
            } else if className == "HierarchicalShapeStyle" {
                let mirror = Mirror(reflecting: provider)
                if let rawValue = mirror.descendant("id") as? UInt32,
                   let level = ResolvedStyle.Kind.HierarchicalLevel(rawValue: Int(rawValue))
                {
                    return ResolvedStyle(kind: .hierarchical(level, nil))
                }
            } else if className.hasPrefix("ShapeStyleBox") {
                let mirror = Mirror(reflecting: provider)
                if let provider = mirror.descendant("base") {
                    return resolve(provider: provider)
                }
            } else if className == "SystemColorsStyle" {
                return ResolvedStyle(kind: .color(.primary))
            } else if className.hasPrefix("_OpacityShapeStyle") {
                let mirror = Mirror(reflecting: provider)
                if let opacity = mirror.descendant("opacity") as? Float,
                    let provider = mirror.descendant("style"),
                    var resolved = resolve(provider: provider)
                {
                    resolved.opacity *= Double(opacity)
                    return resolved
                }
            } else if className.hasPrefix("_BlendModeShapeStyle") {
                let mirror = Mirror(reflecting: provider)
                if let blendMode = mirror.descendant("blendMode") as? BlendMode,
                   let provider = mirror.descendant("style"),
                   var resolved = resolve(provider: provider)
                {
                    resolved.blendMode = blendMode
                    return resolved
                }
            } else if className.hasPrefix("_ShadowShapeStyle") {
                let mirror = Mirror(reflecting: provider)
                if let provider = mirror.descendant("style"),
                    let resolved = resolve(provider: provider)
                {
                    return resolved
                }
            } else if className.hasPrefix("OffsetShapeStyle") {
                let mirror = Mirror(reflecting: provider)
                if let offset = mirror.descendant("offset") as? Int,
                    let level = ResolvedStyle.Kind.HierarchicalLevel(rawValue: offset),
                    let provider = mirror.descendant("base"),
                    var resolved = resolve(provider: provider)
                {
                    resolved.kind = .hierarchical(level, resolved.kind)
                    return resolved
                }
            }
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *),
                let style = provider as? (any ShapeStyle)
            {
                func project<S: ShapeStyle>(_ s: S) -> ResolvedStyle? {
                    guard S.Resolved.self != Never.self else { return nil }
                    let provider = style.resolve(in: environment)
                    return resolve(provider: provider)
                }
                if let resolved = _openExistential(style, do: project) {
                    return resolved
                }
            }
            os_log(.error, log: .default, "Failed to resolve AnyShapeStyle provider %{public}@. Please file an issue.", className)
            return nil
        }
        return resolve(provider: self)
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AnyShapeStyle_Previews: PreviewProvider {

    struct CustomStyle: ShapeStyle {
        func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
            Color.green
        }
    }

    struct CustomGradientStyle: ShapeStyle {
        func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
            Color.green.gradient
        }
    }

    struct StyleColorPreview<S: ShapeStyle>: View {
        var style: AnyShapeStyle

        init(style: S) {
            self.style = AnyShapeStyle(style)
        }

        var body: some View {
            HStack {
                Rectangle()
                    .fill(style)

                EnvironmentValueReader(\.self) { environment in
                    if let resolved = style.resolve(in: environment) {
                        if let color = resolved.kind.color(in: environment) {
                            Rectangle()
                                .fill(color)
                                .opacity(resolved.opacity)
                                .blendMode(resolved.blendMode)
                        } else {
                            Text(verbatim: "\(resolved.kind)")
                        }
                    } else {
                        Text("Failed")
                    }
                }

                EnvironmentValueReader(\.self) { environment in
                    if let resolved = environment.foregroundStyle.resolve(in: environment) {
                        if let color = resolved.kind.color(in: environment) {
                            Rectangle()
                                .fill(color)
                                .opacity(resolved.opacity)
                                .blendMode(resolved.blendMode)
                        } else {
                            Text(verbatim: "\(resolved.kind)")
                        }
                    } else {
                        Text("Failed")
                    }
                }
                .foregroundStyle(S.self == ForegroundStyle.self ? nil : style)
            }
        }
    }

    static var previews: some View {
        VStack {
            StyleColorPreview(style: .red)

            StyleColorPreview(style: .red.blendMode(.difference).opacity(0.3))

            StyleColorPreview(style: .red.opacity(0.3))

            StyleColorPreview(style: .red.gradient)

            StyleColorPreview(style: .red.gradient.opacity(0.3))

            StyleColorPreview(style: .red.shadow(.inner(radius: 4)))

            StyleColorPreview(style: Color(hue: 1, saturation: 0.5, brightness: 0.5))

            StyleColorPreview(style: CustomStyle())

            StyleColorPreview(style: CustomStyle().opacity(0.3))

            StyleColorPreview(style: CustomStyle().blendMode(.difference))

            StyleColorPreview(style: CustomGradientStyle())

            StyleColorPreview(style: .primary)

            StyleColorPreview(style: .secondary)

            Group {
                StyleColorPreview(style: .primary)
                StyleColorPreview(style: .secondary)
                StyleColorPreview(style: .tertiary)
                StyleColorPreview(style: .quaternary)

                if #available(iOS 16.0, macOS 12.0, macCatalyst 15.0, tvOS 17.0, watchOS 10.0, *) {
                    StyleColorPreview(style: .quinary)
                }

                StyleColorPreview(style: .primary.opacity(0.5))
                StyleColorPreview(style: .primary.blendMode(.difference))
                StyleColorPreview(style: .primary.blendMode(.difference).opacity(0.5))
            }
            .foregroundStyle(Color.blue)

            StyleColorPreview(style: .foreground)

            StyleColorPreview(style: .foreground)
                .foregroundStyle(Color.yellow)

            StyleColorPreview(style: .background)
                .contrast(0.5)

            StyleColorPreview(style: .background)
                .backgroundStyle(Color.yellow)

            StyleColorPreview(style: .tint)

            StyleColorPreview(style: .tint)
                .tint(.purple)

            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *) {
                StyleColorPreview(style: .ultraThinMaterial)
            }

            // Not supported
            StyleColorPreview(
                style: LinearGradient.linearGradient(
                    colors: [.yellow, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}
