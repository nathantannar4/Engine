//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Text {

    public static let space = Text(verbatim: " ")

    public static let newline = Text(verbatim: "\n")

    @_disfavoredOverload
    public init?<S: StringProtocol>(_ content: S?) {
        guard let content, !content.isEmpty else { return nil }
        self = Text(content)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Text {

    public init?<Subject>(
        _ subject: Subject?,
        formatter: Formatter
    ) where Subject: ReferenceConvertible {
        guard let subject else { return nil }
        self = Text(subject, formatter: formatter)
    }

    public init?(_ date: Date?, style: Text.DateStyle) {
        guard let date else { return nil }
        self = Text(date, style: style)
    }

    public init?(_ dates: ClosedRange<Date>?) {
        guard let dates else { return nil }
        self = Text(dates)
    }

    public init?(_ interval: DateInterval?) {
        guard let interval else { return nil }
        self = Text(interval)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Text {

    @_disfavoredOverload
    public init?(_ content: AttributedString?) {
        guard let content, !content.characters.isEmpty else { return nil }
        self = Text(content)
    }

    @_disfavoredOverload
    public init?<F>(
        _ input: F.FormatInput?,
        format: F
    ) where F: FormatStyle, F.FormatInput: Equatable, F.FormatOutput == String {
        guard let input else { return nil }
        self.init(input, format: format)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension Text {

    public init?<F>(
        _ input: F.FormatInput?,
        format: F
    ) where F: FormatStyle, F.FormatInput: Equatable, F.FormatOutput == AttributedString {
        guard let input else { return nil }
        self.init(input, format: format)
    }
}


@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Text {

    /// Transforms the `Text` to a `String`, using the environment to resolve localized
    /// string keys if necessary.
    @inlinable
    public func resolve(in environment: EnvironmentValues) -> String {
        _resolveText(in: environment)
    }

    /// Transforms the `Text` to a `AttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func resolveAttributed(in environment: EnvironmentValues) -> AttributedString {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return AttributedString(resolve(in: environment))
        }
        return _resolveAttributed(in: environment)
    }

    /// Transforms the `Text` to a `NSAttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func resolveAttributed(in environment: EnvironmentValues) -> NSAttributedString? {
        #if os(macOS)
        return try? NSAttributedString(
            resolveAttributed(in: environment).toAppKit(in: environment),
            including: \.appKit
        )
        #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
        return try? NSAttributedString(
            resolveAttributed(in: environment).toUIKit(in: environment),
            including: \.uiKit
        )
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Text {
    private enum Storage {
        case verbatim(String)
        case anyTextStorage(AnyObject)
    }

    private enum Modifier {
        case color(Color?)
        case font(Font?)
        case italic
        case weight(Font.Weight?)
        case kerning(CGFloat)
        case tracking(CGFloat)
        case baseline(CGFloat)
        case rounded
        case anyTextModifier(AnyObject)
    }

    private struct ResolvedEnvironment {
        var font: Font?
        var fontWeight: Font.Weight?
        var fontWidth: CGFloat?
        var fontDesign: Font.Design?
        var foregroundColor: Color?
        var underlineStyle: Text.LineStyle?
        var strikethroughStyle: Text.LineStyle?
        var kerning: CGFloat?
        var tracking: CGFloat?
        var baselineOffset: CGFloat?
        var isItalic: Bool = false
        var isBold: Bool = false
        var isMonospaced: Bool = false
        var isMonospacedDigit: Bool = false
        var environment: EnvironmentValues

        init(environment: EnvironmentValues) {
            self.environment = environment
        }

        var attributes: AttributeContainer {
            var attributes = AttributeContainer()
            attributes.swiftUI.font = {
                var font = font ?? environment.font ?? .body
                if let fontDesign {
                    switch fontDesign {
                    case .monospaced:
                        font = font.monospaced()
                    case .default:
                        break
                    default:
                        let style: Font.TextStyle? = {
                            switch font {
                            case .largeTitle: return .largeTitle
                            case .title: return .title
                            case .title2: return .title2
                            case .title3: return .title3
                            case .headline: return .headline
                            case .subheadline: return .subheadline
                            case .body: return .body
                            case .callout: return .callout
                            case .caption: return .caption
                            case .caption2: return .caption2
                            case .footnote: return .footnote
                            default:
                                #if os(visionOS)
                                if font == .extraLargeTitle {
                                    return .extraLargeTitle
                                }
                                if font == .extraLargeTitle2 {
                                    return .extraLargeTitle2
                                }
                                #endif
                                return nil
                            }
                        }()
                        if let style {
                            font = .system(style, design: fontDesign)
                        }
                    }
                }
                if let fontWeight {
                    font = font.weight(fontWeight)
                }
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *), let fontWidth {
                    font = font.width(.init(fontWidth))
                }
                if isItalic {
                    font = font.italic()
                }
                if isBold {
                    font = font.bold()
                }
                if isMonospaced {
                    font = font.monospaced()
                }
                return font
            }()
            attributes.swiftUI.foregroundColor = foregroundColor ?? environment.foregroundColor
            attributes.swiftUI.underlineStyle = underlineStyle ?? environment.underlineStyle
            attributes.swiftUI.strikethroughStyle = strikethroughStyle ?? environment.strikethroughStyle
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                attributes.kern = kerning ?? environment.kerning
                attributes.tracking = tracking ?? environment.tracking
                attributes.baselineOffset = baselineOffset ?? environment.baselineOffset
            } else {
                attributes.swiftUI.kern = kerning
                attributes.swiftUI.tracking = tracking
                attributes.swiftUI.baselineOffset = baselineOffset
            }
            return attributes
        }
    }

    private struct TypeLayout {
        var storage: Storage
        var modifiers: [Modifier]
    }

    private var layout: Text.TypeLayout {
        unsafeBitCast(self, to: Text.TypeLayout.self)
    }

    func _resolveAttributed(in environment: EnvironmentValues) -> AttributedString {
        let environment = ResolvedEnvironment(environment: environment)
        return _resolveAttributed(in: environment)
    }

    private func _resolveAttributed(in environment: ResolvedEnvironment) -> AttributedString {
        var environment = environment
        for modifier in layout.modifiers.reversed() {
            switch modifier {
            case .color(let color):
                environment.foregroundColor = color
            case .font(let font):
                environment.font = font
            case .italic:
                environment.isItalic = true
            case .weight(let weight):
                environment.fontWeight = weight
            case .kerning(let kerning):
                environment.kerning = kerning
            case .tracking(let tracking):
                environment.tracking = tracking
            case .baseline(let baseline):
                environment.baselineOffset = baseline
            case .rounded:
                environment.fontDesign = .rounded
            case .anyTextModifier(let modifier):
                let mirror = Mirror(reflecting: modifier)
                let className = String(describing: type(of: modifier))
                switch className {
                case "TextWidthModifier":
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                        let width = mirror.descendant("width") as? CGFloat
                    {
                        environment.fontWidth = width
                    }
                case "TextDesignModifier":
                    if let design = mirror.descendant("design") as? Font.Design {
                        environment.fontDesign = design
                    }
                case "UnderlineTextModifier":
                    if let lineStyle = mirror.descendant("lineStyle") as? Text.LineStyle {
                        environment.underlineStyle = lineStyle
                    }
                case "BoldTextModifier":
                    if let isActive = mirror.descendant("isActive") as? Bool {
                        environment.isBold = isActive
                    }
                case "StrikethroughTextModifier":
                    if let lineStyle = mirror.descendant("lineStyle") as? Text.LineStyle {
                        environment.strikethroughStyle = lineStyle
                    }
                case "MonospacedTextModifier":
                    if let isActive = mirror.descendant("isActive") as? Bool {
                        environment.isMonospaced = isActive
                    }
                case "MonospacedDigitTextModifier":
                    environment.isMonospacedDigit = true
                default:
                    break
                }
            }
        }
        var attributedString: AttributedString
        switch layout.storage {
        case .verbatim(let text):
            attributedString = AttributedString(
                text,
                attributes: environment.attributes
            )

        case .anyTextStorage(let storage):
            attributedString = resolve(storage: storage, environment: environment)
        }

        if environment.isMonospacedDigit {
            var currentIndex = attributedString.startIndex
            while currentIndex < attributedString.endIndex {
                let nextIndex = attributedString.index(afterCharacter: currentIndex)
                defer { currentIndex = nextIndex }
                guard let character = attributedString[currentIndex..<nextIndex].characters.first else { continue }
                if character.isNumber, let font = attributedString[currentIndex..<nextIndex].swiftUI.font {
                    attributedString[currentIndex..<nextIndex].swiftUI.font = font.monospacedDigit()
                }
            }
        }
        return attributedString
    }

    private func resolve(
        storage: Any,
        environment: ResolvedEnvironment
    ) -> AttributedString {
        let className = String(describing: type(of: storage))
        switch className {
        case "ConcatenatedTextStorage":
            let mirror = Mirror(reflecting: storage)
            guard
                let first = mirror.descendant("first") as? Text,
                let second = mirror.descendant("second") as? Text
            else {
                fallthrough
            }
            return first._resolveAttributed(in: environment) + second._resolveAttributed(in: environment)

        case "AttachmentTextStorage":
            guard let image = Mirror(reflecting: storage).descendant("image") as? Image else {
                fallthrough
            }
            var attributedString = AttributedString.attachment
            #if os(iOS) || os(tvOS) || os(visionOS)
            if let image = image.toUIImage() {
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                    let baselineOffset = environment.baselineOffset,
                    baselineOffset != 0
                {
                    attributedString.attachment = NSTextAttachment(
                        image: image.withBaselineOffset(fromBottom: baselineOffset)
                    )
                } else {
                    attributedString.attachment = NSTextAttachment(
                        image: image
                    )
                }
            }
            #elseif os(macOS)
            if let image = image.toNSImage() {
                let attachment = NSTextAttachment()
                attachment.image = image
                attributedString.attachment = attachment
            }
            #endif
            return attributedString

        default:
            return AttributedString(
                resolve(in: environment.environment),
                attributes: environment.attributes
            )
        }
    }
}

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
#if hasAttribute(retroactive)
extension NSTextAttachment: @unchecked @retroactive Sendable { }
#else
extension NSTextAttachment: @unchecked Sendable { }
#endif
#endif

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct Text_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let optionalText: Optional<String> = "Hello, World"
            Text(optionalText)

            let emptyText: Optional<String> = ""
            if Text(emptyText) == nil {
                Text(verbatim: "Empty")
            }

            if Text(Optional<String>.none) == nil {
                Text(verbatim: "Nil")
            }
        }
    }
}
