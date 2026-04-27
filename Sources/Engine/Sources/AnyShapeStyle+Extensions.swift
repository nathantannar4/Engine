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
            case tuple(AnyShapeStyle, AnyShapeStyle, AnyShapeStyle?)
            case foreground
            case background
            case selection
            case separator
            case tint
            case placeholder
            case link
            case fill
            case windowBackground

            func color(in environment: EnvironmentValues, level: Int = 0) -> Color? {
                switch self {
                case .color(let color):
                    return color

                case .hierarchical(let level, let kind):
                    if level == .secondary, case .color(let color) = kind, color == .primary {
                        return .secondary
                    }
                    return kind?.color(in: environment)?.opacity(level.opacity)

                case .tuple(let primary, let secondary, let tertiary):
                    switch level {
                    case 0:
                        return primary.color(in: environment)
                    case 1:
                        return secondary.color(in: environment)
                    default:
                        return tertiary?.color(in: environment)
                    }

                case .tint:
                    if let resolvedTint = environment.tintStyle.resolve(in: environment) {
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

    public func color(in environment: EnvironmentValues, level: Int = 0) -> Color? {
        guard
            let style = resolve(in: environment),
            let color = style.kind.color(in: environment, level: level)
        else {
            return nil
        }
        return color.opacity(style.opacity)
    }

    public func blendMode(in environment: EnvironmentValues) -> BlendMode? {
        let style = resolve(in: environment)
        return style?.blendMode
    }

    public func resolve(in environment: EnvironmentValues) -> ResolvedStyle? {
        func resolve(provider: Any) -> ResolvedStyle? {
            let className = String(describing: type(of: provider))
            if className == "AnyShapeStyle" {
                let mirror = Mirror(reflecting: provider)
                if let provider = try? swift_getFieldValue("storage", Any.self, provider),
                    let box = try? swift_getFieldValue("box", Any.self, provider)
                {
                    return resolve(provider: box)
                }
            } else if className == "Color", let color = provider as? Color {
                return ResolvedStyle(kind: .color(color))
            } else if className == "Material", let material = provider as? Material {
                return ResolvedStyle(kind: .material(material))
            } else if className.hasPrefix("ColorBox") {
                let color = unsafeBitCast(provider as AnyObject, to: Color.self)
                return ResolvedStyle(kind: .color(color))
            } else if className == "AnyGradient" {
                if let provider = try? swift_getFieldValue("provider", Any.self, provider) {
                    return resolve(provider: provider)
                }
            } else if className.hasPrefix("GradientBox") {
                if let base = try? swift_getFieldValue("base", Any.self, provider),
                    let color = try? swift_getFieldValue("color", Any.self, base),
                    let provider = try? swift_getFieldValue("provider", Any.self, color)
                {
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
                if let rawValue = try? swift_getFieldValue("id", Int32.self, provider),
                   let level = ResolvedStyle.Kind.HierarchicalLevel(rawValue: Int(rawValue))
                {
                    return ResolvedStyle(kind: .hierarchical(level, nil))
                }
            } else if className.hasPrefix("ShapeStylePair") || className.hasPrefix("ShapeStyleTriple") {
                if let primary = try? swift_getFieldValue("primary", AnyShapeStyle.self, provider),
                   let secondary = try? swift_getFieldValue("secondary", AnyShapeStyle.self, provider)
                {
                    let tertiary = try? swift_getFieldValue("tertiary", AnyShapeStyle.self, provider)
                    return ResolvedStyle(
                        kind: .tuple(
                            primary,
                            secondary,
                            tertiary
                        )
                    )
                }
            } else if className.hasPrefix("ShapeStyleBox") {
                if let base = try? swift_getFieldValue("base", Any.self, provider) {
                    return resolve(provider: base)
                }
            } else if className == "SystemColorsStyle" {
                return ResolvedStyle(kind: .color(.primary))
            } else if className.hasPrefix("_OpacityShapeStyle") {
                if let opacity = try? swift_getFieldValue("opacity", Float.self, provider),
                    let style = try? swift_getFieldValue("style", Any.self, provider),
                    var resolved = resolve(provider: style)
                {
                    resolved.opacity *= Double(opacity)
                    return resolved
                }
            } else if className.hasPrefix("_BlendModeShapeStyle") {
                if let blendMode = try? swift_getFieldValue("blendMode", BlendMode.self, provider),
                    let style = try? swift_getFieldValue("style", Any.self, provider),
                    var resolved = resolve(provider: style)
                {
                    resolved.blendMode = blendMode
                    return resolved
                }
            } else if className.hasPrefix("_ShadowShapeStyle") {
                if let style = try? swift_getFieldValue("style", Any.self, provider),
                    let resolved = resolve(provider: style)
                {
                    return resolved
                }
            } else if className.hasPrefix("OffsetShapeStyle") {
                if let offset = try? swift_getFieldValue("offset", Int.self, provider),
                    let level = ResolvedStyle.Kind.HierarchicalLevel(rawValue: offset),
                    let base = try? swift_getFieldValue("base", Any.self, provider),
                    var resolved = resolve(provider: base)
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
        var level: Int

        init(style: S, level: Int = 0) {
            self.style = AnyShapeStyle(style)
            self.level = level
        }

        var body: some View {
            HStack {
                Rectangle()
                    .fill(style)

                EnvironmentValueReader(\.self) { environment in
                    if let resolved = style.resolve(in: environment) {
                        if let color = resolved.kind.color(in: environment, level: level) {
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
                        if let color = resolved.kind.color(in: environment, level: level) {
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

            EnvironmentValueReader(\.foregroundStyle) { style in
                Group {
                    StyleColorPreview(style: style)
                    StyleColorPreview(style: style, level: 1)
                }
            }
            .foregroundStyle(Color.red, Color.orange)

            EnvironmentValueReader(\.foregroundStyle) { style in
                Group {
                    StyleColorPreview(style: style)
                    StyleColorPreview(style: style, level: 1)
                    StyleColorPreview(style: style, level: 2)
                }
            }
            .foregroundStyle(Color.red, Color.orange, Color.yellow)

            StyleColorPreview(style: .foreground)

            StyleColorPreview(style: .foreground)
                .foregroundStyle(Color.yellow)

            StyleColorPreview(style: .background)
                .backgroundStyle(Color.green)

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
