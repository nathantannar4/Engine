//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
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

    @inlinable
    @inline(__always)
    public static var bulletPoint: Text {
        Text("• ")
    }

    @inlinable
    @inline(__always)
    public static var ellipsis: Text {
        Text("…")
    }

    @inlinable
    @inline(__always)
    public init(prefix: Text, _ key: LocalizedStringKey) {
        self = prefix + Text(key)
    }

    @inlinable
    @inline(__always)
    public init(prefix: Text, _ text: Text) {
        self = prefix + text
    }

    @inlinable
    @inline(__always)
    public init(_ key: LocalizedStringKey, suffix: Text) {
        self = Text(key) + suffix
    }

    @inlinable
    @inline(__always)
    public init(_ text: Text, suffix: Text) {
        self = text + suffix
    }

    @_disfavoredOverload
    public init?<S: StringProtocol>(_ content: S?) {
        guard let content, !content.isEmpty else { return nil }
        self = Text(content)
    }

    @_disfavoredOverload
    public init?(
        _ key: LocalizedStringKey?,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) {
        guard let key else { return nil }
        self = Text(key, tableName: tableName, bundle: bundle, comment: comment)
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

    public init?(_ image: Image?) {
        guard let image else { return nil }
        self = Text(image)
    }

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

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public var attachment: Image? {
        guard let storage else { return nil }
        return try? swift_getFieldValue("image", Image.self, storage)
    }

    public var isVerbatim: Bool {
        storage == nil
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func sizeThatFits(
        _ proposal: ProposedSize,
        environment: EnvironmentValues
    ) -> CGSize {
        let fittingSize = proposal
            .replacingUnspecifiedDimensions(
                by: CGSize(
                    width: CGFloat.infinity,
                    height: CGFloat.infinity
                )
            )
        return sizeThatFits(fittingSize, environment: environment)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func sizeThatFits(
        _ size: CGSize,
        environment: EnvironmentValues
    ) -> CGSize {
        let attributedString: NSAttributedString = resolveAttributed(in: environment)
        return attributedString.sizeThatFits(
            size: size,
            lineLimit: environment.lineLimit,
            minimumScaleFactor: environment.minimumScaleFactor,
            displayScale: environment.displayScale
        )
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

    struct AttachmentTextStorageTypeLayout {
        var metadata: (Any.Type, UInt)
        var image: Image?
    }

    private var storageLayout: Text.TypeLayout {
        unsafeBitCast(self, to: Text.TypeLayout.self)
    }

    private var storage: AnyObject? {
        switch layout.storage {
        case .verbatim:
            return nil
        case .anyTextStorage(let storage):
            return storage
        }
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
                self.color = try? swift_getFieldValue("color", Color.self, lineStyle)
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

            var multiplier: CGFloat {
                switch self {
                case .default:
                    return 1
                case .secondary:
                    return 0.84
                }
            }

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
                } else if scale == .secondary {
                    font = font.weight(.medium)
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
                if let scale, scale == .secondary, let platformFont = font.toPlatformValue(in: environment) {
                    font = Font(platformFont.withSize(platformFont.pointSize * scale.multiplier))
                }
                return font
            }()
            attributes.swiftUI.foregroundColor = foregroundColor ?? environment.foregroundColor
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                attributes.swiftUI.underlineStyle = underlineStyle?.toSwiftUI() ?? environment.underlineStyle
                attributes.swiftUI.strikethroughStyle = strikethroughStyle?.toSwiftUI() ?? environment.strikethroughStyle
                let kerning = kerning ?? environment.kerning
                attributes.kern = kerning != 0 ? kerning : nil
                let tracking = tracking ?? environment.tracking
                attributes.tracking = tracking != 0 ? tracking : nil
                let baselineOffset = baselineOffset ?? environment.baselineOffset
                attributes.baselineOffset = baselineOffset != 0 ? baselineOffset : nil
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
                } else if scale == .secondary {
                    font = font.weight(.medium)
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
                if let scale, scale == .secondary, let platformFont = font.toPlatformValue(in: environment) {
                    return platformFont.withSize(platformFont.pointSize * scale.multiplier)
                }
                return font.toPlatformValue(in: environment)
            }()
            let foregroundColor: Color.PlatformRepresentable? = {
                if let foregroundColor = self.foregroundColor {
                    return foregroundColor.toPlatformValue(in: environment)
                }
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                    let foregroundColor = environment.foregroundColor
                {
                    return foregroundColor.toPlatformValue(in: environment)
                }
                return nil
            }()
            attributes[.foregroundColor] = foregroundColor
            let underlineStyle: NSUnderlineStyle? = {
                if let underlineStyle = self.underlineStyle {
                    return underlineStyle.style
                }
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                    let underlineStyle = environment.underlineStyle
                {
                    return NSUnderlineStyle(underlineStyle)
                }
                return nil
            }()
            attributes[.underlineStyle] = underlineStyle?.rawValue
            attributes[.underlineColor] = {
                if let color = self.underlineStyle?.color {
                    return color.toPlatformValue(in: environment)
                }
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                    let underlineStyle = environment.underlineStyle,
                    let color = LineStyle(lineStyle: underlineStyle).color
                {
                    return color.toPlatformValue(in: environment)
                }
                return foregroundColor
            }()
            let strikethroughStyle: NSUnderlineStyle? = {
                if let strikethroughStyle = self.strikethroughStyle {
                    return strikethroughStyle.style
                }
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                   let strikethroughStyle = environment.strikethroughStyle
                {
                    return NSUnderlineStyle(strikethroughStyle)
                }
                return nil
            }()
            attributes[.strikethroughStyle] = strikethroughStyle?.rawValue
            attributes[.strikethroughColor] = {
                if let color = self.strikethroughStyle?.color {
                    return color.toPlatformValue(in: environment)
                }
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                    let strikethroughStyle = environment.strikethroughStyle,
                    let color = LineStyle(lineStyle: strikethroughStyle).color
                {
                    return color.toPlatformValue(in: environment)
                }
                return foregroundColor
            }()
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                let kerning = kerning ?? environment.kerning
                attributes[.kern] = kerning != 0 ? kerning : nil
                let tracking = tracking ?? environment.tracking
                attributes[.tracking] = tracking != 0 ? tracking : nil
                let baselineOffset = baselineOffset ?? environment.baselineOffset
                attributes[.baselineOffset] = baselineOffset != 0 ? baselineOffset : nil
            } else {
                attributes[.kern] = kerning
                attributes[.tracking] = tracking
                attributes[.baselineOffset] = baselineOffset
            }
            let paragraphStyle = NSMutableParagraphStyle()
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                paragraphStyle.lineSpacing = environment.lineSpacing
                if let lineHeight = environment.lineHeight?.storage {
                    switch lineHeight {
                    case .exact(let height):
                        paragraphStyle.minimumLineHeight = height
                        paragraphStyle.maximumLineHeight = height
                    case .leading(let increase):
                        paragraphStyle.lineSpacing = increase
                    case .multiple(let multiple):
                        paragraphStyle.lineHeightMultiple = multiple
                    }
                }
            }
            #endif
            switch environment.multilineTextAlignment {
            case .leading:
                paragraphStyle.alignment = environment.layoutDirection == .leftToRight ? .left : .right
            case .trailing:
                paragraphStyle.alignment = environment.layoutDirection == .leftToRight ? .right : .left
            case .center:
                paragraphStyle.alignment = .center
            }
            attributes[.paragraphStyle] = paragraphStyle.copy() as! NSParagraphStyle
            return attributes
        }
    }

    private struct Resolved {
        indirect enum Storage {
            struct Element {
                enum Storage {
                    case text(String, arguments: [Resolved])
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
                    case .text(let string, let arguments):
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
                        if !arguments.isEmpty {
                            var location = attributedString.startIndex
                            for argument in arguments {
                                let substring = argument.storage.resolveAttributedString()
                                if let substringRange = attributedString.range(of: String(substring.characters)), substringRange.lowerBound >= location {
                                    for run in substring.runs {
                                        let offset = substring.characters.distance(from: substring.startIndex, to: run.range.lowerBound)
                                        let length = substring.characters.distance(from: run.range.lowerBound, to: run.range.upperBound)
                                        let lower = attributedString.characters.index(substringRange.lowerBound, offsetBy: offset)
                                        let upper = attributedString.characters.index(lower, offsetBy: length)
                                        attributedString[lower..<upper].mergeAttributes(run.attributes, mergePolicy: .keepNew)
                                    }
                                    location = substringRange.upperBound
                                }
                            }
                        }
                        return attributedString

                    case .image(let image):
                        let attributeContainer = element.attributes.attributeContainer
                        var attributedString = AttributedString.attachment(attributes: attributeContainer)
                        var environment = element.attributes.environment
                        if let font = attributeContainer.swiftUI.font {
                            environment.font = font
                        }
                        if var image = image.toPlatformValue(in: environment) {
                            #if os(iOS) || os(tvOS) || os(visionOS)
                            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                               let baselineOffset = attributeContainer.swiftUI.baselineOffset,
                               baselineOffset != 0
                            {
                                image = image.withBaselineOffset(fromBottom: baselineOffset)
                            }
                            attributedString.attachment = NSTextAttachment(image: image)
                            #elseif os(macOS)
                            let attachment = NSTextAttachment()
                            attachment.image = image
                            attributedString.attachment = attachment
                            #endif
                        }
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
                    case .text(let string, let arguments):
                        let attributedString = NSAttributedString(
                            string: string,
                            attributes: element.attributes.attributes
                        )
                        if !arguments.isEmpty {
                            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                            var location = 0
                            for argument in arguments {
                                let substring = argument.storage.resolveNSAttributedString()
                                let substringRange = mutableAttributedString.mutableString.range(
                                    of: substring.string,
                                    range: NSRange(location: location, length: attributedString.length - location)
                                )
                                if substringRange.location != NSNotFound {
                                    substring.enumerateAttributes(
                                        in: NSRange(location: 0, length: substring.length)
                                    ) { attributes, range, _ in
                                        let subrange = NSRange(
                                            location: range.location + substringRange.location,
                                            length: range.length
                                        )
                                        mutableAttributedString.setAttributes(attributes, range: subrange)
                                    }
                                    location = NSMaxRange(substringRange)
                                }
                            }
                            return mutableAttributedString.copy() as! NSAttributedString
                        }
                        return attributedString

                    case .image(let image):
                        let attachment = NSTextAttachment()
                        var environment = element.attributes.environment
                        let attributes = element.attributes.attributes
                        if let font = attributes[.font] as? Font.PlatformRepresentable {
                            environment.font = Font(font)
                        }
                        attachment.image = image.toPlatformValue(in: environment)
                        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                            return NSAttributedString(
                                attachment: attachment,
                                attributes: attributes
                            )
                        } else {
                            let attributedString = NSMutableAttributedString(attachment: attachment)
                            attributedString.setAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
                            return attributedString.copy() as! NSAttributedString
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
                let className = String(describing: type(of: modifier))
                switch className {
                case "TextWidthModifier":
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                        let width = try? swift_getFieldValue("width", CGFloat.self, modifier)
                    {
                        attributes.fontWidth = width
                    }
                case "TextDesignModifier":
                    if let design = try? swift_getFieldValue("design", Font.Design.self, modifier){
                        attributes.fontDesign = design
                    }
                case "UnderlineTextModifier":
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                        let lineStyle = try? swift_getFieldValue("lineStyle", Text.LineStyle.self, modifier)
                    {
                        attributes.underlineStyle = .init(lineStyle: lineStyle)
                    }
                case "BoldTextModifier":
                    if let isActive = try? swift_getFieldValue("isActive", Bool.self, modifier) {
                        attributes.isBold = isActive
                    }
                case "StrikethroughTextModifier":
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                        let lineStyle = try? swift_getFieldValue("lineStyle", Text.LineStyle.self, modifier)
                    {
                        attributes.strikethroughStyle = .init(lineStyle: lineStyle)
                    }
                case "MonospacedTextModifier":
                    if let isActive = try? swift_getFieldValue("isActive", Bool.self, modifier) {
                        attributes.isMonospaced = isActive
                    }
                case "MonospacedDigitTextModifier":
                    attributes.isMonospacedDigit = true
                case "TextScaleModifier":
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *),
                        let scale = try? swift_getFieldValue("scale", Text.Scale.self, modifier),
                        (try? swift_getFieldValue("isEnabled", Bool.self, modifier)) ?? true
                    {
                        attributes.scale = .init(scale: scale)
                    }
                default:
                    os_log(.debug, log: .default, "Failed to resolve Text modifier %{public}@. Please file an issue.", className)
                    break
                }
            }
        }
        switch layout.storage {
        case .verbatim(let text):
            return Resolved(
                storage: .element(
                    .init(
                        storage: .text(text, arguments: []),
                        attributes: attributes
                    )
                )
            )

        case .anyTextStorage(let storage):
            return resolve(storage: storage, attributes: attributes)
        }
    }

    private func resolve(
        storage: AnyObject,
        attributes: ResolvedAttributes
    ) -> Resolved {
        let className = String(describing: type(of: storage))
        switch className {
        case "ConcatenatedTextStorage":
            guard
                let first = try? swift_getFieldValue("first", Text.self, storage),
                let second = try? swift_getFieldValue("second", Text.self, storage)
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
            guard
                let image = try? swift_getFieldValue("image", Image.self, storage)
            else {
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

        case "LocalizedTextStorage":
            guard
                let key = try? swift_getFieldValue("key", LocalizedStringKey.self, storage),
                let hasFormatting = try? swift_getFieldValue("hasFormatting", Bool.self, key),
                hasFormatting,
                let rawArguments = try? swift_getFieldValue("arguments", Any.self, key) as? [Any],
                rawArguments.count > 0
            else {
                fallthrough
            }

            let arguments = rawArguments
                .compactMap { try? swift_getFieldValue("storage", Any.self, $0) }
                .compactMap { Mirror(reflecting: $0).descendant("text", ".0") as? Text }
                .map { $0._resolve(with: attributes) }

            return Resolved(
                storage: .element(
                    .init(
                        storage: .text(resolve(in: attributes.environment), arguments: arguments),
                        attributes: attributes
                    )
                )
            )

        default:
            return Resolved(
                storage: .element(
                    .init(
                        storage: .text(resolve(in: attributes.environment), arguments: []),
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

#if canImport(FoundationModels) // Xcode 26
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension AttributedString.LineHeight {

    enum Storage {
        case multiple(factor: CGFloat)
        case leading(increase: CGFloat)
        case exact(point: CGFloat)
    }

    var storage: Storage? {
        try? swift_getFieldValue("baselineInterval", Storage.self, self)
    }
}
#endif

extension Text.TruncationMode {

    func toNSLineBreakMode(lineLimit: Int?) -> NSLineBreakMode {
        if lineLimit ?? -1 <= 0 {
            return .byWordWrapping
        }
        switch self {
        case .head:
            return .byTruncatingHead
        case .middle:
            return .byTruncatingMiddle
        case .tail:
            return .byTruncatingTail
        @unknown default:
            return .byWordWrapping
        }
    }
}

extension NSAttributedString {

    func sizeThatFits(
        size: CGSize,
        lineLimit: Int? = nil,
        minimumScaleFactor: CGFloat = 1,
        displayScale: CGFloat
    ) -> CGSize {
        let context = NSStringDrawingContext()
        context.minimumScaleFactor = minimumScaleFactor

        #if os(macOS)
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
        #else
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
        #endif
        var sizeThatFits = boundingRect(
            with: size,
            options: options,
            context: context
        ).size

        if let lineLimit, lineLimit > 1 {
            sizeThatFits.width = boundingRect(
               with: size,
               options: options.subtracting(.usesLineFragmentOrigin),
               context: context
            ).size.width
        }

        if context.minimumScaleFactor < 1, context.actualScaleFactor < 1 {
            let mutableAttributedString = NSMutableAttributedString(attributedString: self)
            mutableAttributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
                guard let font = value as? Font.PlatformRepresentable else { return }
                let scaledFont = font.withSize(floor(font.pointSize * context.actualScaleFactor))
                mutableAttributedString.addAttribute(.font, value: scaledFont, range: range)
            }
            sizeThatFits = mutableAttributedString.boundingRect(
                with: size,
                options: options,
                context: context
            ).size
        }

        sizeThatFits.height = sizeThatFits.height.rounded(scale: displayScale)
        sizeThatFits.width = sizeThatFits.width.rounded(scale: displayScale)
        return sizeThatFits
    }
}

// MARK: - Previews

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

            let optionalKey: LocalizedStringKey? = "Cancel"
            Text(optionalKey)

            if Text(Optional<LocalizedStringKey>.none) == nil {
                Text(verbatim: "Nil")
            }

            Text("Search", suffix: .ellipsis)

            Text(prefix: .bulletPoint, "Line 1")

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Text("Search", suffix: .ellipsis)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
