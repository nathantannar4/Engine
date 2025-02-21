//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Font {

    #if os(macOS)
    typealias PlatformRepresentable = NSFont
    typealias PlatformRepresentableDescriptor = NSFontDescriptor
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIFont
    typealias PlatformRepresentableDescriptor = UIFontDescriptor
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func toUIFont() -> UIFont? {
        toPlatformValue()
    }
    #endif

    #if os(macOS)
    @available(macOS 11.0, *)
    public func toNSFont() -> NSFont? {
        toPlatformValue()
    }
    #endif

    @available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
    fileprivate func toPlatformValue() -> PlatformRepresentable? {
        FontProvider(for: self)?.resolved()
    }
}

@available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
private enum FontProvider {
    case system(size: CGFloat, weight: Font.Weight?, design: Font.Design?)
    case textStyle(Font.TextStyle, weight: Font.Weight?, design: Font.Design?)
    case platform(CTFont)
    case named(Font.PlatformRepresentable)

    init?(for font: Font) {
        guard let base = Mirror(reflecting: font).descendant("provider", "base") else {
            return nil
        }

        let className = String(describing: type(of: base))
        let mirror = Mirror(reflecting: base)

        if let regex = try? NSRegularExpression(
            pattern: "ModifierProvider<(.*)>"
        ), let match = regex.firstMatch(
            in: className,
            range: NSRange(className.startIndex..<className.endIndex, in: className)
        ) {
            let modifier = className[Range(match.range(at: 1), in: className)!]

            guard let sFont = mirror.descendant("base") as? Font,
                  var font = sFont.toPlatformValue()
            else {
                return nil
            }

            switch modifier {
            case "BoldModifier":
                font = font.bold ?? font
                break

            case "ItalicModifier":
                font = font.italic ?? font
                break

            case "MonospacedModifier":
                font = font.monospaced ?? font
                break

            case "MonospacedDigitModifier":
                font = font.with(featureType: kNumberSpacingType, selector: kMonospacedNumbersSelector) ?? font
                break

            case "WeightModifier":
                if let weight = mirror.descendant("modifier", "weight", "value") as? CGFloat {
                    font = font.with(weight: Font.PlatformRepresentable.Weight(rawValue: weight)) ?? font
                }
                break

            case "WidthModifier":
                if #available(watchOS 9.0, *) {
                    if let width = mirror.descendant("modifier", "width") as? CGFloat {
                        font = font.with(width: Font.PlatformRepresentable.Width(rawValue: width)) ?? font
                    }
                }
                break

            case "LeadingModifier":
                break

            case "FeatureSettingModifier":
                if let type = mirror.descendant("modifier", "type") as? Int,
                   let selector = mirror.descendant("modifier", "selector") as? Int
                {
                    font = font.with(featureType: type, selector: selector) ?? font
                }
                break

            default:
                break
            }

            self = .named(font)
            return
        }

        switch className {
        case "SystemProvider":
            guard let size = mirror.descendant("size") as? CGFloat else {
                return nil
            }
            let weight = mirror.descendant("weight") as? Font.Weight
            let design = mirror.descendant("design") as? Font.Design
            self = .system(size: size, weight: weight, design: design)

        case "TextStyleProvider":
            guard let style = mirror.descendant("style") as?  Font.TextStyle else {
                return nil
            }
            let weight = mirror.descendant("weight") as? Font.Weight
            let design = mirror.descendant("design") as? Font.Design
            self = .textStyle(style, weight: weight, design: design)

        case "PlatformFontProvider":
            guard let font = mirror.descendant("font") as? Font.PlatformRepresentable else {
                return nil
            }
            self = .platform(font)
        case "NamedProvider":
            guard
                let name = mirror.descendant("name") as? String,
                let size = mirror.descendant("size") as? CGFloat,
                let font = Font.PlatformRepresentable(name: name, size: size)
            else {
                return nil
            }

            #if os(macOS)
            self = .named(font)
            #else
            if let textStyle = mirror.descendant("textStyle") as? Font.TextStyle,
               let textStyle = Font.PlatformRepresentable.TextStyle(textStyle)
            {
                let metrics = UIFontMetrics(forTextStyle: textStyle)
                self = .named(metrics.scaledFont(for: font))
            } else {
                self = .named(font)
            }
            #endif

        default:
            return nil
        }
    }

    func resolved() -> Font.PlatformRepresentable? {
        switch self {
        case let .system(size, weight, design):
            let font: Font.PlatformRepresentable
            if let weight, let fontWeight = Font.PlatformRepresentable.Weight(weight) {
                font = Font.PlatformRepresentable.systemFont(ofSize: size, weight: fontWeight)
            } else {
                font = Font.PlatformRepresentable.systemFont(ofSize: size)
            }
            if let design, let systemDesign = Font.PlatformRepresentableDescriptor.SystemDesign(design) {
                return font.with(design: systemDesign) ?? font
            }
            return font

        case let .textStyle(textStyle, weight, design):
            guard let textStyle = Font.PlatformRepresentable.TextStyle(textStyle) else {
                return nil
            }
            var font = Font.PlatformRepresentable.preferredFont(
                forTextStyle: textStyle
            )
            if let weight, let weight = Font.PlatformRepresentable.Weight(weight) {
                font = font.with(weight: weight) ?? font
            }
            if let design, let design = Font.PlatformRepresentableDescriptor.SystemDesign(design) {
                font = font.with(design: design) ?? font
            }
            return font

        case let .platform(font):
            return font as Font.PlatformRepresentable

        case let .named(font):
            return font
        }
    }
}

fileprivate extension Font.PlatformRepresentable {
    func with(
        design: Font.PlatformRepresentableDescriptor.SystemDesign
    ) -> Font.PlatformRepresentable? {
        guard let designedDescriptor = fontDescriptor.withDesign(design) else {
            return nil
        }
        return Font.PlatformRepresentable(
            descriptor: designedDescriptor,
            size: pointSize
        )
    }

    func with(
        featureType type: Int,
        selector: Int
    ) -> Font.PlatformRepresentable? {
        #if os(macOS)
        return nil
        #elseif os(visionOS)
        with(
            feature: [
                Font.PlatformRepresentableDescriptor.FeatureKey.type: type as Int,
                Font.PlatformRepresentableDescriptor.FeatureKey.selector: selector as Int
            ]
        )
        #else
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return with(
                feature: [
                    Font.PlatformRepresentableDescriptor.FeatureKey.type: type as Int,
                    Font.PlatformRepresentableDescriptor.FeatureKey.selector: selector as Int
                ]
            )
        }
        return with(
            feature: [
                Font.PlatformRepresentableDescriptor.FeatureKey.featureIdentifier: type as Int,
                Font.PlatformRepresentableDescriptor.FeatureKey.typeIdentifier: selector as Int
            ]
        )
        #endif
    }

    var bold: Font.PlatformRepresentable? {
        with(symbolicTraits: .traitBold)
    }

    var italic: Font.PlatformRepresentable? {
        with(symbolicTraits: .traitItalic)
    }

    var monospaced: Font.PlatformRepresentable? {
        let traits = CTFontCopyTraits(self) as NSDictionary
        let weight: Font.PlatformRepresentable.Weight
        if let existingWeight = traits[kCTFontWeightTrait as String] as? CGFloat {
            weight = Font.PlatformRepresentable.Weight(rawValue: existingWeight)
        } else {
            weight = .regular
        }
        #if os(watchOS)
        if #available(watchOS 7.0, *) {
            return with(design: .monospaced)?.with(weight: weight)
        } else {
            return nil
        }
        #else
        return with(design: .monospaced)?.with(weight: weight)
        #endif
    }

    @available(watchOS 9.0, *)
    func with(
        width: Width
    ) -> Font.PlatformRepresentable? {
        let traits = NSMutableDictionary(dictionary: CTFontCopyTraits(self))
        traits[kCTFontWidthTrait as String] = width

        var fontAttributes: [Font.PlatformRepresentableDescriptor.AttributeName: Any] = [:]
        fontAttributes[.family] = familyName
        fontAttributes[.traits] = traits

        let font = Font.PlatformRepresentable(
            descriptor: Font.PlatformRepresentableDescriptor(fontAttributes: fontAttributes),
            size: pointSize
        )
        #if os(macOS)
        guard let font else {
            return nil
        }
        #endif
        return font
    }

    func with(
        weight: Weight? = nil,
        symbolicTraits: CTFontSymbolicTraits = [],
        feature: [Font.PlatformRepresentableDescriptor.FeatureKey: Int]? = nil
    ) -> Font.PlatformRepresentable? {
        var mergedSymbolicTraits = CTFontGetSymbolicTraits(self)
        mergedSymbolicTraits.formUnion(symbolicTraits)

        let traits = NSMutableDictionary(dictionary: CTFontCopyTraits(self))
        if let weight {
            traits[kCTFontWeightTrait as String] = weight
        }
        traits[kCTFontSymbolicTrait as String] = mergedSymbolicTraits.rawValue

        var fontAttributes: [Font.PlatformRepresentableDescriptor.AttributeName: Any] = [:]
        fontAttributes[.family] = familyName
        fontAttributes[.traits] = traits

        if let feature {
            var mergedFeatureSettings = fontAttributes[.featureSettings] as? [[Font.PlatformRepresentableDescriptor.FeatureKey: Int]] ?? []
            mergedFeatureSettings.append(
                feature
            )
            fontAttributes[.featureSettings] = mergedFeatureSettings
        }

        let font = Font.PlatformRepresentable(
            descriptor: Font.PlatformRepresentableDescriptor(fontAttributes: fontAttributes),
            size: pointSize
        )
        #if os(macOS)
        guard let font else {
            return nil
        }
        #endif
        if symbolicTraits != [] {
            return CTFontCreateCopyWithSymbolicTraits(font, 0, nil, mergedSymbolicTraits, symbolicTraits) ?? font
        }
        return font
    }
}

fileprivate extension Font.PlatformRepresentableDescriptor.SystemDesign {
    init?(_ design: Font.Design) {
        switch design {
        case .default:
            self = .default
        case .serif:
            #if os(watchOS)
            if #available(watchOS 7.0, *) {
                self = .serif
            } else {
                return nil
            }
            #else
            self = .serif
            #endif
        case .rounded:
            self = .rounded
        case .monospaced:
            #if os(watchOS)
            if #available(watchOS 7.0, *) {
                self = .monospaced
            } else {
                return nil
            }
            #else
            self = .monospaced
            #endif
        @unknown default:
            return nil
        }
    }
}

fileprivate extension Font.PlatformRepresentable.Weight {
    init?(_ weight: Font.Weight) {
        guard let rawValue = Mirror(reflecting: weight).descendant("value") as? CGFloat else {
            return nil
        }
        self = Font.PlatformRepresentable.Weight(rawValue)
    }
}

@available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
fileprivate extension Font.PlatformRepresentable.TextStyle {
    init?(_ textStyle: Font.TextStyle) {
        switch textStyle {
        case .largeTitle:
            #if os(tvOS)
            return nil
            #else
            self = .largeTitle
            #endif
        case .extraLargeTitle:
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
                self = .extraLargeTitle
            }
            #endif
            return nil
        case .extraLargeTitle2:
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
                self = .extraLargeTitle2
            }
            #endif
            return nil
        case .title:
            self = .title1
        case .headline:
            self = .headline
        case .subheadline:
            self = .subheadline
        case .body:
            self = .body
        case .callout:
            self = .callout
        case .footnote:
            self = .footnote
        case .caption:
            self = .caption1
        case .title2:
            self = .title2
        case .title3:
            self = .title3
        case .caption2:
            self = .caption2
        @unknown default:
            return nil
        }
    }
}

// MARK: - Previews

#if os(iOS) || os(macOS)
@available(iOS 14.0, macOS 11.0, *)
struct Font_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(
            columns: [
                .init(.adaptive(minimum: 100)),
                .init(.adaptive(minimum: 100)),
            ],
            spacing: 20
        ) {
            FontPreview(font: .body)

            FontPreview(font: .body.italic())

            FontPreview(font: .body.bold())

            if #available(iOS 16.0, macOS 13.0, *) {
                FontPreview(font: .body)
                    .bold()
                    .italic()
            }

            if #available(iOS 15.0, macOS 12.0, *) {
                FontPreview(font: .body.monospaced())

                FontPreview(font: .body.monospaced().weight(.bold))
            }

            FontPreview(font: .body.monospacedDigit())

            if #available(iOS 16.0, macOS 13.0, *) {
                FontPreview(font: Font(Font.PlatformRepresentable.systemFont(ofSize: 15, weight: .thin, width: .expanded)))
            }

            if #available(iOS 16.0, macOS 13.0, *) {
                FontPreview(font: .body)
                    .underline()
            }

            if #available(iOS 16.0,macOS 13.0,  *) {
                FontPreview(font: .body)
                    .kerning(3)
            }

            if #available(iOS 16.0, macOS 13.0, *) {
                FontPreview(font: .system(.body, design: .rounded, weight: .semibold))
            }

            if #available(iOS 16.0,macOS 13.0,  *) {
                FontPreview(font: .body)
                    .fontWidth(.compressed)
            }
        }
    }

    struct FontPreview: View {
        var font: Font

        var body: some View {
            VStack {
                Text("Hello, World 123")

                EnvironmentValueReader(\.font) { font in
                    if let font = font?.toPlatformValue() {
                        Text("Hello, World 123")
                            .font(Font(font))
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .font(font)
        }
    }
}
#endif
