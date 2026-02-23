//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

extension Text {

    @inlinable
    @inline(__always)
    public static var space: Text {
        Text(" ")
    }

    @inlinable
    @inline(__always)
    public static var newline: Text {
        Text("\n")
    }

    @_disfavoredOverload
    public init?<S: StringProtocol>(_ content: S?) {
        guard let content, !content.isEmpty else { return nil }
        self = Text(content)
    }

    /// Returns the verbatim value if the text stores a `String`
    public var verbatim: String? {
        guard
            MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size,
            case .verbatim(let verbatim) = layout.storage
        else {
            return nil
        }
        return verbatim
    }

    /// Returns `true` if the text stores a `String` that is empty
    public var isEmpty: Bool {
        verbatim?.isEmpty ?? false
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
        return _resolve(in: environment).storage.resolveAttributedString()
    }

    /// Transforms the `Text` to a `NSAttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @_disfavoredOverload
    public func resolveAttributed(in environment: EnvironmentValues) -> NSAttributedString {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return NSAttributedString(string: resolve(in: environment))
        }
        return _resolve(in: environment).storage.resolveNSAttributedString()
    }
}

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

    private struct TypeLayout {
        var storage: Storage
        var modifiers: [Modifier]
    }

    private var layout: Text.TypeLayout {
        unsafeBitCast(self, to: Text.TypeLayout.self)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Text {

    private struct ResolvedAttributes {
        var font: Font?
        var fontWeight: Font.Weight?
        var fontWidth: CGFloat?
        var fontDesign: Font.Design?
        var foregroundColor: Color?
        var underlineStyle: LineStyle?
        var strikethroughStyle: LineStyle?
        var kerning: CGFloat?
        var tracking: CGFloat?
        var baselineOffset: CGFloat?
        var isItalic: Bool = false
        var isBold: Bool = false
        var isMonospaced: Bool = false
        var isMonospacedDigit: Bool = false
        var scale: Scale?
        var environment: EnvironmentValues

        struct LineStyle {
            var style: NSUnderlineStyle
            var color: Color?

            init(style: NSUnderlineStyle, color: Color? = nil) {
                self.style = style
                self.color = color
            }

            @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
            init(lineStyle: Text.LineStyle) {
                self.style = NSUnderlineStyle(lineStyle)
                self.color = Mirror(reflecting: lineStyle).descendant("color") as? Color
            }

            @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
            func toSwiftUI() -> Text.LineStyle {
                let pattern = unsafeBitCast(style, to: Text.LineStyle.Pattern.self)
                return Text.LineStyle(
                    pattern: pattern,
                    color: color
                )
            }
        }

        enum Scale {
            case `default`
            case secondary

            @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
            init(scale: Text.Scale) {
                switch scale {
                case .secondary:
                    self = .secondary
                default:
                    self = .default
                }
            }

            @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
            func toSwiftUI() -> Text.Scale {
                switch self {
                case .secondary:
                    return .secondary
                default:
                    return .default
                }
            }
        }

        init(environment: EnvironmentValues) {
            self.environment = environment
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        var attributeContainer: AttributeContainer {
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
            attributes.swiftUI.underlineStyle = underlineStyle?.toSwiftUI() ?? environment.underlineStyle
            attributes.swiftUI.strikethroughStyle = strikethroughStyle?.toSwiftUI() ?? environment.strikethroughStyle
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                attributes.kern = kerning ?? environment.kerning
                attributes.tracking = tracking ?? environment.tracking
                attributes.baselineOffset = baselineOffset ?? environment.baselineOffset
            } else {
                attributes.swiftUI.kern = kerning
                attributes.swiftUI.tracking = tracking
                attributes.swiftUI.baselineOffset = baselineOffset
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                attributes.swiftUI.lineHeight = environment.lineHeight
                switch environment.multilineTextAlignment {
                case .leading:
                    attributes.swiftUI.alignment = environment.layoutDirection == .leftToRight ? .left : .right
                case .trailing:
                    attributes.swiftUI.alignment = environment.layoutDirection == .leftToRight ? .right : .left
                case .center:
                    attributes.swiftUI.alignment = .center
                }
            }
            #endif
            return attributes
        }

        var attributes: [NSAttributedString.Key: Any] {
            var attributes = [NSAttributedString.Key: Any]()
            attributes[.font] = {
                var font = font ?? environment.font ?? .body
                if let fontDesign {
                    switch fontDesign {
                    case .monospaced:
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            font = font.monospaced()
                        }
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
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), isMonospaced {
                    font = font.monospaced()
                }
                return font.toPlatformValue()
            }()
            let foregroundColor: Color.PlatformRepresentable? = {
                if let foregroundColor = self.foregroundColor {
                    return foregroundColor.toPlatformValue()
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                    let foregroundColor = environment.foregroundColor
                {
                    return foregroundColor.toPlatformValue()
                }
                return nil
            }()
            attributes[.foregroundColor] = foregroundColor
            let underlineStyle: NSUnderlineStyle? = {
                if let underlineStyle = self.underlineStyle {
                    return underlineStyle.style
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                    let underlineStyle = environment.underlineStyle
                {
                    return NSUnderlineStyle(underlineStyle)
                }
                return nil
            }()
            attributes[.underlineStyle] = underlineStyle?.rawValue
            attributes[.underlineColor] = {
                if let color = self.underlineStyle?.color {
                    return color.toPlatformValue()
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                    let underlineStyle = environment.underlineStyle,
                    let color = LineStyle(lineStyle: underlineStyle).color
                {
                    return color.toPlatformValue()
                }
                return foregroundColor
            }()
            let strikethroughStyle: NSUnderlineStyle? = {
                if let strikethroughStyle = self.strikethroughStyle {
                    return strikethroughStyle.style
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                   let strikethroughStyle = environment.strikethroughStyle
                {
                    return NSUnderlineStyle(strikethroughStyle)
                }
                return nil
            }()
            attributes[.strikethroughStyle] = strikethroughStyle?.rawValue
            attributes[.strikethroughColor] = {
                if let color = self.strikethroughStyle?.color {
                    return color.toPlatformValue()
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                    let strikethroughStyle = environment.strikethroughStyle,
                    let color = LineStyle(lineStyle: strikethroughStyle).color
                {
                    return color.toPlatformValue()
                }
                return foregroundColor
            }()
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                attributes[.kern] = kerning ?? environment.kerning
                attributes[.tracking] = tracking ?? environment.tracking
                attributes[.baselineOffset] = baselineOffset ?? environment.baselineOffset
            } else {
                attributes[.kern] = kerning
                attributes[.tracking] = tracking
                attributes[.baselineOffset] = baselineOffset
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = environment.lineSpacing
                switch environment.multilineTextAlignment {
                case .leading:
                    paragraphStyle.alignment = environment.layoutDirection == .leftToRight ? .left : .right
                case .trailing:
                    paragraphStyle.alignment = environment.layoutDirection == .leftToRight ? .right : .left
                case .center:
                    paragraphStyle.alignment = .center
                }
                attributes[.paragraphStyle] = paragraphStyle
            }
            #endif
            return attributes
        }
    }

    private struct Resolved {
        indirect enum Storage {
            struct Element {
                enum Storage {
                    case text(String)
                    case image(Image)
                }
                var storage: Storage
                var attributes: ResolvedAttributes
            }
            case element(Element)

            case concatenated(Resolved, Resolved)

            @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
            func resolveAttributedString() -> AttributedString {
                switch self {
                case .element(let element):
                    switch element.storage {
                    case .text(let string):
                        var attributedString = AttributedString(
                            string,
                            attributes: element.attributes.attributeContainer
                        )
                        if element.attributes.isMonospacedDigit {
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

                    case .image(let image):
                        let attributeContainer = element.attributes.attributeContainer
                        var attributedString = AttributedString.attachment(attributes: attributeContainer)
                        #if os(iOS) || os(tvOS) || os(visionOS)
                        if let image = image.toUIImage() {
                            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                               let baselineOffset = attributeContainer.swiftUI.baselineOffset,
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
                    }

                case .concatenated(let first, let second):
                    return first.storage.resolveAttributedString() + second.storage.resolveAttributedString()
                }
            }

            func resolveNSAttributedString() -> NSAttributedString {
                switch self {
                case .element(let element):
                    switch element.storage {
                    case .text(let string):
                        return NSAttributedString(
                            string: string,
                            attributes: element.attributes.attributes
                        )
                    case .image(let image):
                        let attachment = NSTextAttachment()
                        attachment.image = image.toPlatformValue(in: element.attributes.environment)
                        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                            return NSAttributedString(
                                attachment: attachment,
                                attributes: element.attributes.attributes
                            )
                        } else {
                            return NSAttributedString(attachment: attachment)
                        }
                    }
                case .concatenated(let first, let second):
                    let attributedString = NSMutableAttributedString()
                    attributedString.append(first.storage.resolveNSAttributedString())
                    attributedString.append(second.storage.resolveNSAttributedString())
                    return attributedString
                }
            }
        }
        var storage: Storage
    }

    private func _resolve(
        in environment: EnvironmentValues
    ) -> Resolved {
        let attributes = ResolvedAttributes(environment: environment)
        return _resolve(with: attributes)
    }

    private func _resolve(
        with attributes: ResolvedAttributes
    ) -> Resolved {
        var attributes = attributes
        for modifier in layout.modifiers.reversed() {
            switch modifier {
            case .color(let color):
                attributes.foregroundColor = color
            case .font(let font):
                attributes.font = font
            case .italic:
                attributes.isItalic = true
            case .weight(let weight):
                attributes.fontWeight = weight
            case .kerning(let kerning):
                attributes.kerning = kerning
            case .tracking(let tracking):
                attributes.tracking = tracking
            case .baseline(let baseline):
                attributes.baselineOffset = baseline
            case .rounded:
                attributes.fontDesign = .rounded
            case .anyTextModifier(let modifier):
                let mirror = Mirror(reflecting: modifier)
                let className = String(describing: type(of: modifier))
                switch className {
                case "TextWidthModifier":
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                        let width = mirror.descendant("width") as? CGFloat
                    {
                        attributes.fontWidth = width
                    }
                case "TextDesignModifier":
                    if let design = mirror.descendant("design") as? Font.Design {
                        attributes.fontDesign = design
                    }
                case "UnderlineTextModifier":
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                        let lineStyle = mirror.descendant("lineStyle") as? Text.LineStyle
                    {
                        attributes.underlineStyle = .init(lineStyle: lineStyle)
                    }
                case "BoldTextModifier":
                    if let isActive = mirror.descendant("isActive") as? Bool {
                        attributes.isBold = isActive
                    }
                case "StrikethroughTextModifier":
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                        let lineStyle = mirror.descendant("lineStyle") as? Text.LineStyle
                    {
                        attributes.strikethroughStyle = .init(lineStyle: lineStyle)
                    }
                case "MonospacedTextModifier":
                    if let isActive = mirror.descendant("isActive") as? Bool {
                        attributes.isMonospaced = isActive
                    }
                case "MonospacedDigitTextModifier":
                    attributes.isMonospacedDigit = true
                case "TextScaleModifier":
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *),
                        let scale = mirror.descendant("scale") as? Text.Scale,
                        mirror.descendant("isEnabled") as? Bool ?? true
                    {
                        attributes.scale = .init(scale: scale)
                    }
                default:
                    os_log(.error, log: .default, "Failed to resolve Text modifier %{public}@. Please file an issue.", className)
                    break
                }
            }
        }
        switch layout.storage {
        case .verbatim(let text):
            return Resolved(
                storage: .element(
                    .init(
                        storage: .text(text),
                        attributes: attributes
                    )
                )
            )

        case .anyTextStorage(let storage):
            return resolve(storage: storage, attributes: attributes)
        }
    }

    private func resolve(
        storage: Any,
        attributes: ResolvedAttributes
    ) -> Resolved {
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
            return Resolved(
                storage: .concatenated(
                    first._resolve(with: attributes),
                    second._resolve(with: attributes)
                )
            )

        case "AttachmentTextStorage":
            guard let image = Mirror(reflecting: storage).descendant("image") as? Image else {
                fallthrough
            }
            return Resolved(
                storage: .element(
                    .init(
                        storage: .image(image),
                        attributes: attributes
                    )
                )
            )

        default:
            return Resolved(
                storage: .element(
                    .init(
                        storage: .text(resolve(in: attributes.environment)),
                        attributes: attributes
                    )
                )
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
