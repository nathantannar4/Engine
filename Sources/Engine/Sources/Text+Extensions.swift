//
// Copyright (c) Nathan Tannar
//

import os.log
import SwiftUI
import EngineCore

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public protocol TextAttributeKey: Sendable, TextAttribute, AttributedStringKey where Value == Self { }

extension Text {

    @inlinable
    @inline(__always)
    public static var space: Text {
        Text(" ")
    }

    @inlinable
    @inline(__always)
    public static var dotSeparator: Text {
        Text(" · ")
    }

    @inlinable
    @inline(__always)
    public static var dashSeparator: Text {
        Text(" — ")
    }

    @inlinable
    @inline(__always)
    public static var newline: Text {
        Text("\n")
    }

    @inlinable
    @inline(__always)
    public static var bulletPointSeparator: Text {
        Text("• ")
    }

    @inlinable
    @inline(__always)
    public static var backSlashSeparator: Text {
        Text(" / ")
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

    @inlinable
    @inline(__always)
    public init(spaces count: Int) {
        // Unicode character for a space that line wraps
        self = Text(String(repeating: "\u{2800}", count: count))
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

    public var isVerbatim: Bool {
        verbatim != nil
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

    public var attachment: Image? {
        guard
            MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size,
            case .anyTextStorage(let storage) = layout.storage
        else {
            return nil
        }
        return try? swift_getFieldValue("image", Image.self, storage)
    }

    /// Returns `true` if there are any attributed styling modifiers or attachments on the `Text`
    public var isAttributed: Bool {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return false
        }
        return resolveHasAttributes()
    }

    /// Returns `true` if the text would resolve to empty
    public var isEmpty: Bool {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return false
        }
        return resolveIsEmpty()
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

    public init?<F>(
        _ input: F.FormatInput?,
        format: F
    ) where F: FormatStyle, F.FormatInput: Equatable, F.FormatOutput == String {
        guard let input else { return nil }
        self.init(input, format: format)
    }

    public init<UnitType: Dimension>(
        _ input: Measurement<UnitType>,
        format: Measurement<UnitType>.FormatStyle,
        unitsFont: Font?
    ) {
        if let unitsFont {
            var str = format.attributed.format(input)
            str = str.transformingAttributes(
                \.measurement, \.font
            ) { measurement, font in
                if measurement.value == .unit {
                    font.value = unitsFont
                }
            }
            self.init(str)
        } else {
            self.init(input, format: format)
        }
    }

    public init?<UnitType: Dimension>(
        _ input: Measurement<UnitType>?,
        format: Measurement<UnitType>.FormatStyle,
        unitsFont: Font?
    ) {
        guard let input else { return nil }
        self.init(input, format: format, unitsFont: unitsFont)
    }

    public init<Value: BinaryFloatingPoint>(
        _ input: Value,
        format: FloatingPointFormatStyle<Value>.Currency,
        currencyFont: Font?,
        decimalFont: Font?
    ) {
        if currencyFont != nil || decimalFont != nil {
            var str = format.attributed.format(input)
            str = str.transformingAttributes(
                \.numberPart, \.numberSymbol, \.font
            ) { numberPart, numberSymbol, font in
                if let currencyFont, numberSymbol.value == .currency {
                    font.value = currencyFont
                }
                if let decimalFont, numberPart.value == .fraction || numberSymbol.value == .decimalSeparator {
                    font.value = decimalFont
                }
            }
            self.init(str)
        } else {
            self.init(input, format: format)
        }
    }

    public init?<Value: BinaryFloatingPoint>(
        _ input: Value?,
        format: FloatingPointFormatStyle<Value>.Currency,
        currencyFont: Font?,
        decimalFont: Font?
    ) {
        guard let input else { return nil }
        self.init(input, format: format, currencyFont: currencyFont, decimalFont: decimalFont)
    }

    public init<Value: BinaryFloatingPoint>(
        _ input: Value,
        format: FloatingPointFormatStyle<Value>.Percent,
        percentFont: Font?,
        decimalFont: Font?
    ) {
        if percentFont != nil || decimalFont != nil {
            var str = format.attributed.format(input)
            str = str.transformingAttributes(
                \.numberPart, \.numberSymbol, \.font
            ) { numberPart, numberSymbol, font in
                if let percentFont, numberSymbol.value == .percent {
                    font.value = percentFont
                }
                if let decimalFont, numberPart.value == .fraction || numberSymbol.value == .decimalSeparator {
                    font.value = decimalFont
                }
            }
            self.init(str)
        } else {
            self.init(input, format: format)
        }
    }

    public init?<Value: BinaryFloatingPoint>(
        _ input: Value?,
        format: FloatingPointFormatStyle<Value>.Currency,
        percentFont: Font?,
        decimalFont: Font?
    ) {
        guard let input else { return nil }
        self.init(input, format: format, percentFont: percentFont, decimalFont: decimalFont)
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
        if let verbatim {
            return verbatim
        }
        return _resolveText(in: environment)
    }

    /// Transforms the `Text` to a `AttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func resolveAttributed(in environment: EnvironmentValues) -> AttributedString {
        return resolveAttributedString(in: environment)
    }

    /// Transforms the `Text` to a `NSAttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @_disfavoredOverload
    public func resolveAttributed(in environment: EnvironmentValues) -> NSAttributedString {
        return resolveNSAttributedString(in: environment)
    }

    /// Transforms the `Text` to a `AttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func resolveAttributedString(in environment: EnvironmentValues) -> AttributedString {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return AttributedString(resolve(in: environment))
        }
        return _resolveAttributed(in: environment).resolveAttributedString(in: environment)
    }

    /// Transforms the `Text` to a `NSAttributedString`, using the environment to resolve localized
    /// string keys if necessary.
    public func resolveNSAttributedString(in environment: EnvironmentValues) -> NSAttributedString {
        guard MemoryLayout<Text>.size == MemoryLayout<Text.TypeLayout>.size else {
            return NSAttributedString(string: resolve(in: environment))
        }
        return _resolveAttributed(in: environment).resolveNSAttributedString(in: environment)
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
            lineBreakMode: environment.truncationMode.toNSLineBreakMode(lineLimit: environment.lineLimit),
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

        var hasAttributes: Bool {
            switch self {
            case .color(let color):
                return color != nil
            case .font(let font):
                return font != nil
            case .weight(let weight):
                return weight != nil
            case .italic, .kerning, .tracking, .baseline, .rounded, .anyTextModifier:
                return true
            }
        }
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
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Text {

    fileprivate func _resolveAttributed(
        in environment: EnvironmentValues
    ) -> ResolvedText {
        let storage = resolveTextStorage()
        let attributes = resolveAttributes(in: environment)
        return ResolvedText(storage: storage, attributes: attributes)
    }

    fileprivate func resolveAttributes(
        in environment: EnvironmentValues
    ) -> ResolvedTextAttributes {
        var attributes = ResolvedTextAttributes()
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
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *),
                        let scale = try? swift_getFieldValue("scale", Text.Scale.self, modifier),
                        (try? swift_getFieldValue("isEnabled", Bool.self, modifier)) ?? true
                    {
                        attributes.scale = .init(scale: scale)
                    }
                case "TextForegroundStyleModifier":
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *),
                        let style = try? swift_getFieldValue("style", AnyShapeStyle.self, modifier),
                        let color = style.color(in: environment)
                    {
                        attributes.foregroundColor = color
                    }
                default:
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *),
                        className.hasPrefix("TextAttributeModifier"),
                        let value = try? swift_getFieldValue("value", Any.self, modifier)
                    {
                        attributes.customAttributes.append(value)
                    } else {
                        os_log(.debug, log: .default, "Failed to resolve Text modifier %{public}@. Please file an issue.", className)
                    }
                }
            }
        }
        return attributes
    }

    private func resolveTextStorage() -> ResolvedTextStorage {
        switch layout.storage {
        case .verbatim(let string):
            return VerbatimStringStorage(string: string)

        case .anyTextStorage(let storage):
            return resolveTextStorage(storage: storage)
        }
    }

    private func resolveTextStorage(storage: AnyObject) -> ResolvedTextStorage {
        let className = String(describing: type(of: storage))
        switch className {
        case "ConcatenatedTextStorage":
            guard
                let first = try? swift_getFieldValue("first", Text.self, storage),
                let second = try? swift_getFieldValue("second", Text.self, storage)
            else {
                fallthrough
            }
            return ConcatenatedTextStorage(
                first: first,
                second: second
            )

        case "AttachmentTextStorage":
            guard
                let image = try? swift_getFieldValue("image", Image.self, storage)
            else {
                fallthrough
            }
            return AttachmentTextStorage(
                image: image
            )

        case "AttributedStringTextStorage":
            guard
                #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
                let attributedString = try? swift_getFieldValue("str", AttributedString.self, storage)
            else {
                fallthrough
            }
            return AttributedStringTextStorage(
                attributedString: attributedString
            )

        case "LocalizedTextStorage":
            guard
                let key = try? swift_getFieldValue("key", LocalizedStringKey.self, storage)
            else {
                fallthrough
            }
            let table = try? swift_getFieldValue("table", String?.self, storage)
            let bundle = try? swift_getFieldValue("bundle", Bundle?.self, storage)
            return LocalizedTextStorage(
                key: key,
                table: table,
                bundle: bundle
            )

        default:
            return TextStorage(
                text: self
            )
        }
    }
}

extension Text {

    private func resolveIsEmpty() -> Bool {
        switch layout.storage {
        case .verbatim(let text):
            return text.isEmpty
        case .anyTextStorage(let storage):
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                let storage = resolveTextStorage(storage: storage)
                return storage.resolveIsEmpty()
            }
            return false
        }
    }

    private func resolveHasAttributes() -> Bool {
        if layout.modifiers.contains(where: { $0.hasAttributes }) {
            return true
        }
        switch layout.storage {
        case .verbatim:
            return false
        case .anyTextStorage(let storage):
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                let storage = resolveTextStorage(storage: storage)
                return storage.resolveHasAttributes()
            }
            return false
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ResolvedText {
    let storage: ResolvedTextStorage
    let attributes: ResolvedTextAttributes

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with additionalAttributes: ResolvedTextAttributes? = nil
    ) -> AttributedString {
        return storage.resolveAttributedString(
            in: environment,
            with: attributes.merging(attributes: additionalAttributes)
        )
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with additionalAttributes: ResolvedTextAttributes? = nil
    ) -> NSAttributedString {
        return storage.resolveNSAttributedString(
            in: environment,
            with: attributes.merging(attributes: additionalAttributes)
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ResolvedTextAttributes {
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
    var isItalic: Bool?
    var isBold: Bool?
    var isMonospaced: Bool?
    var isMonospacedDigit: Bool?
    var scale: Scale?
    var customAttributes: [Any] = []

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

    func merging(attributes: ResolvedTextAttributes?) -> ResolvedTextAttributes {
        guard let attributes else { return self }
        var merged = self
        if let font = attributes.font {
            merged.font = font
        }
        if let fontWeight = attributes.fontWeight {
            merged.fontWeight = fontWeight
        }
        if let fontWidth = attributes.fontWidth {
            merged.fontWidth = fontWidth
        }
        if let fontDesign = attributes.fontDesign {
            merged.fontDesign = fontDesign
        }
        if let foregroundColor = attributes.foregroundColor {
            merged.foregroundColor = foregroundColor
        }
        if let underlineStyle = attributes.underlineStyle {
            merged.underlineStyle = underlineStyle
        }
        if let strikethroughStyle = attributes.strikethroughStyle {
            merged.strikethroughStyle = strikethroughStyle
        }
        if let kerning = attributes.kerning {
            merged.kerning = kerning
        }
        if let tracking = attributes.tracking {
            merged.tracking = tracking
        }
        if let baselineOffset = attributes.baselineOffset {
            merged.baselineOffset = baselineOffset
        }
        if let isItalic = attributes.isItalic {
            merged.isItalic = isItalic
        }
        if let isBold = attributes.isBold {
            merged.isBold = isBold
        }
        if let isMonospaced = attributes.isMonospaced {
            merged.isMonospaced = isMonospaced
        }
        if let isMonospacedDigit = attributes.isMonospacedDigit {
            merged.isMonospacedDigit = isMonospacedDigit
        }
        if let scale = attributes.scale {
            merged.scale = scale
        }
        merged.customAttributes.append(contentsOf: attributes.customAttributes)
        return merged
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func attributeContainer(in environment: EnvironmentValues) -> AttributeContainer {
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
            if isItalic == true {
                font = font.italic()
            }
            if isBold == true {
                font = font.bold()
            }
            if isMonospaced == true {
                font = font.monospaced()
            }
            if isMonospacedDigit == true {
                font = font.monospacedDigit()
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
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            for attribute in customAttributes {
                if let key = attribute as? any TextAttributeKey {
                    func project<Key: TextAttributeKey>(_ key: Key) {
                        if let value = attribute as? Key.Value {
                            attributes[Key.self] = value
                        }
                    }
                    _openExistential(key, do: project)
                }
            }
        }
        attributes.foundation.languageIdentifier = environment.locale.languageCode
        return attributes
    }

    func attributes(in environment: EnvironmentValues) -> [NSAttributedString.Key: Any] {
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
            if isItalic == true {
                font = font.italic()
            }
            if isBold == true {
                font = font.bold()
            }
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), isMonospaced == true {
                font = font.monospaced()
            }
            if isMonospacedDigit == true {
                font = font.monospacedDigit()
            }
            var platformFont = font.toPlatformValue(in: environment)
            #if !os(watchOS)
            if #unavailable(iOS 16.0, macOS 13.0, tvOS 16.0), let fontWidth {
                platformFont = platformFont?.with(width: Font.PlatformRepresentable.Width(rawValue: fontWidth))
            }
            #endif
            if #unavailable(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0), isMonospaced == true || fontDesign == .monospaced {
                platformFont = platformFont?.monospaced ?? platformFont
            }
            if let scale, scale == .secondary, let font = platformFont {
                platformFont = font.withSize(font.pointSize * scale.multiplier)
            }
            return platformFont
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
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            for attribute in customAttributes {
                if let key = attribute as? any TextAttributeKey {
                    func project<Key: TextAttributeKey>(_ key: Key) {
                        if let value = attribute as? Key.Value {
                            attributes[NSAttributedString.Key(Key.name)] = value
                        }
                    }
                    _openExistential(key, do: project)
                }
            }
        }
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            attributes[.languageIdentifier] = environment.locale.languageCode
        }
        return attributes
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private protocol ResolvedTextStorage {

    func resolveIsEmpty() -> Bool

    func resolveHasAttributes() -> Bool

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class VerbatimStringStorage: ResolvedTextStorage {
    let string: String

    init(string: String) {
        self.string = string
    }

    func resolveIsEmpty() -> Bool {
        return string.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return false
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        return AttributedString(
            string,
            attributes: attributes.attributeContainer(in: environment)
        )
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        return NSAttributedString(
            string: string,
            attributes: attributes.attributes(in: environment)
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class ConcatenatedTextStorage: ResolvedTextStorage {
    let first: Text
    let second: Text

    init(first: Text, second: Text) {
        self.first = first
        self.second = second
    }

    func resolveIsEmpty() -> Bool {
        return first.isEmpty || second.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return first.isAttributed || second.isAttributed
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        let first = first._resolveAttributed(in: environment)
            .resolveAttributedString(in: environment, with: attributes)
        let second = second._resolveAttributed(in: environment)
            .resolveAttributedString(in: environment, with: attributes)
        let attributedString = first + second
        return attributedString
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        let first = first._resolveAttributed(in: environment)
            .resolveNSAttributedString(in: environment, with: attributes)
        let second = second._resolveAttributed(in: environment)
            .resolveNSAttributedString(in: environment, with: attributes)
        let attributedString = NSMutableAttributedString()
        attributedString.append(first)
        attributedString.append(second)
        return attributedString
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class TextStorage: ResolvedTextStorage {
    let text: Text

    init(text: Text) {
        self.text = text
    }

    func resolveIsEmpty() -> Bool {
        return text.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return text.isAttributed
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        let textAttributes = text.resolveAttributes(in: environment)
        return AttributedString(
            text.resolve(in: environment),
            attributes: attributes.merging(attributes: textAttributes).attributeContainer(in: environment)
        )
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        let textAttributes = text.resolveAttributes(in: environment)
        return NSAttributedString(
            string: text.resolve(in: environment),
            attributes: attributes.merging(attributes: textAttributes).attributes(in: environment)
        )
    }
}

private protocol LocalizedTextArgument {

    func resolveIsEmpty() -> Bool

    func resolveHasAttributes() -> Bool

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> AttributedString

    func resolveNSAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> NSAttributedString
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class FormatArgument: LocalizedTextArgument {
    let value: CVarArg
    let formatter: Formatter?

    init(value: CVarArg, formatter: Formatter?) {
        self.value = value
        self.formatter = formatter
    }

    func resolveIsEmpty() -> Bool {
        return false
    }

    func resolveHasAttributes() -> Bool {
        return false
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> AttributedString {
        return AttributedString(resolvedString(format: format))
    }

    func resolveNSAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> NSAttributedString {
        return NSAttributedString(string: resolvedString(format: format))
    }

    private func resolvedString(format: String) -> String {
        if let formatted = formatter?.string(for: value) {
            return formatted
        }
        return String(format: format, value)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class TextStorageArgument: LocalizedTextArgument {
    let text: Text

    init(text: Text) {
        self.text = text
    }

    func resolveIsEmpty() -> Bool {
        return text.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return text.isAttributed
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> AttributedString {
        return text.resolveAttributedString(in: environment)
    }

    func resolveNSAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> NSAttributedString {
        return text.resolveNSAttributedString(in: environment)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class AttributedStringArgument: LocalizedTextArgument {
    let attributedString: AttributedString

    init(attributedString: AttributedString) {
        self.attributedString = attributedString
    }

    func resolveIsEmpty() -> Bool {
        return attributedString.characters.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return attributedString.runs.allSatisfy { $0.attributes == AttributeContainer() }
    }

    func resolveAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> AttributedString {
        return attributedString
    }

    func resolveNSAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> NSAttributedString {
        return attributedString.toNSAttributedString(in: environment)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private class LocalizedStringResourceArgument: LocalizedTextArgument {
    let localizedStringResource: LocalizedStringResource

    init(localizedStringResource: LocalizedStringResource) {
        self.localizedStringResource = localizedStringResource
    }

    func resolveIsEmpty() -> Bool {
        return false
    }

    func resolveHasAttributes() -> Bool {
        return false
    }

    func resolveAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> AttributedString {
        return AttributedString(localized: localizedStringResource)
    }

    func resolveNSAttributedString(
        format: String,
        in environment: EnvironmentValues
    ) -> NSAttributedString {
        return NSAttributedString(string: String(localized: localizedStringResource))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class LocalizedTextStorage: ResolvedTextStorage {
    let key: LocalizedStringKey
    let table: String?
    let bundle: Bundle?
    let arguments: [LocalizedTextArgument]

    init(
        key: LocalizedStringKey,
        table: String?,
        bundle: Bundle?
    ) {
        self.key = key
        self.table = table
        self.bundle = bundle
        if let arguments = try? swift_getFieldValue("arguments", Any.self, key) as? [Any] {
            self.arguments = arguments
                .compactMap {
                    do {
                        let storage = try swift_getFieldValue("storage", Any.self, $0)
                        let kind = try swift_getEnumCase(storage)
                        switch kind {
                        case "value":
                            let (value, formatter) = try swift_getFieldValue("value", (CVarArg, Formatter?).self, storage)
                            return FormatArgument(
                                value: value,
                                formatter: formatter
                            )
                        case "text":
                            let (text, _) = try swift_getFieldValue("text", (Text, Int).self, storage)
                            return TextStorageArgument(
                                text: text
                            )
                        case "attributedString":
                            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                                let attributedString = try swift_getFieldValue("attributedString", AttributedString.self, storage)
                                return AttributedStringArgument(
                                    attributedString: attributedString
                                )
                            }
                        case "localizedStringResource":
                            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                                let localizedStringResource = try swift_getFieldValue("localizedStringResource", LocalizedStringResource.self, storage)
                                return LocalizedStringResourceArgument(
                                    localizedStringResource: localizedStringResource
                                )
                            }
                        default:
                            os_log(.debug, log: .default, "Failed to resolve LocalizedStringKey argument %{public}@. Please file an issue.", kind)
                        }
                    } catch {
                        os_log(.debug, log: .default, "Failed to resolve LocalizedStringKey argument storage %{public}@. Please file an issue.", String(describing: type(of: $0)))
                    }
                    return nil
                }
        } else {
            self.arguments = []
        }
    }

    func resolveIsEmpty() -> Bool {
        return false
    }

    func resolveHasAttributes() -> Bool {
        if hasMarkdown(localized: resolveString()) {
            return true
        }
        return arguments.contains(where: { $0.resolveHasAttributes() })
    }

    func resolveString() -> String {
        let localized = NSLocalizedString(
            key.localizationKey,
            tableName: table,
            bundle: bundle ?? .main,
            value: "",
            comment: ""
        )
        return localized
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        let localized = resolveString()
        var attributedString: AttributedString
        if hasMarkdown(localized: localized) {
            do {
                attributedString = try AttributedString(
                    markdown: localized,
                    including: \.swiftUI,
                    options: .init(
                        allowsExtendedAttributes: true,
                        interpretedSyntax: .full,
                        failurePolicy: .returnPartiallyParsedIfPossible,
                        languageCode: environment.locale.languageCode
                    )
                )
            } catch {
                os_log(.debug, log: .default, "Failed to resolve markdown for key %{public}@. Please file an issue.", localized)
                attributedString = AttributedString(localized)
            }
        } else {
            attributedString = AttributedString(localized)
        }
        if !arguments.isEmpty {
            resolveArguments(in: &attributedString, with: arguments, environment: environment)
        }
        attributedString.mergeAttributes(attributes.attributeContainer(in: environment), mergePolicy: .keepCurrent)
        return attributedString
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        let localized = resolveString()
        var attributedString: NSAttributedString
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), hasMarkdown(localized: localized) {
            do {
                let attrString = try AttributedString(
                    markdown: localized,
                    including: \.swiftUI,
                    options: .init(
                        allowsExtendedAttributes: true,
                        interpretedSyntax: .full,
                        failurePolicy: .returnPartiallyParsedIfPossible,
                        languageCode: environment.locale.languageCode
                    )
                )
                let mutableAttributedString = NSMutableAttributedString(attributedString: attrString.toNSAttributedString(in: environment))
                mutableAttributedString.mergeAttributes(attributes.attributes(in: environment), keepCurrent: true)
                attributedString = mutableAttributedString
            } catch {
                os_log(.debug, log: .default, "Failed to resolve markdown for key %{public}@. Please file an issue.", localized)
                attributedString = NSAttributedString(string: localized, attributes: attributes.attributes(in: environment))
            }
        } else {
            attributedString = NSAttributedString(string: localized, attributes: attributes.attributes(in: environment))
        }
        if !arguments.isEmpty {
            if let mutableAttributedString = attributedString as? NSMutableAttributedString {
                resolveArguments(in: mutableAttributedString, with: arguments, environment: environment)
            } else {
                let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                resolveArguments(in: mutableAttributedString, with: arguments, environment: environment)
                attributedString = mutableAttributedString
            }
        }
        return attributedString
    }

    private func hasMarkdown(localized: String) -> Bool {
        let patterns = [
            #"\*\*.+?\*\*"#,                         // **bold**
            #"__.+?__"#,                             // __bold__
            #"(?<!\*)\*[^*\s][^*]*?\*(?!\*)"#,       // *italic*
            #"(?<!_)_[^_\s][^_]*?_(?!_)"#,           // _italic_ (word-boundary guarded)
            #"`.+?`"#,                               // `code`
            #"~~.+?~~"#,                             // ~~strikethrough~~
            #"\[.+?\]\(.+?\)"#,                      // [text](url) — inline link
            #"\^\[.+?\]\(.+?\)"#,                    // ^[text](key: value, ...) — extended attributes
            #"\[.+?\]\[.*?\]"#,                      // [text][ref] — reference-style link
        ]
        let hasAttributes = patterns.contains { pattern in
            localized.range(of: pattern, options: .regularExpression) != nil
        }
        return hasAttributes
    }

    private func formatArgumentRegex() -> NSRegularExpression {
        // Pattern breakdown:
        // 1. %                        - Start of specifier
        // 2. (?:(\d+)\$)?             - Optional positional argument: "1$" in %1$@
        // 3. [-+#0 ']*                - Optional flags
        // 4. \d*                      - Optional width
        // 5. (?:\.\d+)?               - Optional precision (.2)
        // 6. (?:hh|h|ll|l|q|j|z|t|L)? - Length modifiers (multi-character matched FIRST)
        // 7. [@dduxXoefeEgGaAcCsSp%]  - Specifier type character
        let pattern = #"%(?:(\d+)\$)?[-+#0 ']*\d*(?:\.\d+)?(?:hh|h|ll|l|q|j|z|t|L)?[@dduxXoefeEgGaAcCsSp%]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        return regex
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func resolveArguments(
        in attributedString: inout AttributedString,
        with arguments: [LocalizedTextArgument],
        environment: EnvironmentValues
    ) {
        let rawString = String(attributedString.characters)
        let regex = formatArgumentRegex()
        let matches = regex.matches(in: rawString, options: [], range: NSRange(rawString.startIndex..., in: rawString))

        guard !matches.isEmpty else { return }

        var result = AttributedString()
        var lastIndex = rawString.startIndex
        var argumentIndex = 0

        for match in matches {
            guard
                let matchRange = Range(match.range, in: rawString),
                let attrMatchRange = Range(matchRange, in: attributedString)
            else {
                continue
            }

            if lastIndex < matchRange.lowerBound {
                if let precedingAttrRange = Range(lastIndex..<matchRange.lowerBound, in: attributedString) {
                    result.append(attributedString[precedingAttrRange])
                }
            }
            lastIndex = matchRange.upperBound

            let baseAttributes = attributedString[attrMatchRange].runs.first?.attributes ?? AttributeContainer()
            let formatPiece = String(rawString[matchRange])

            if formatPiece == "%%" {
                result.append(AttributedString("%", attributes: baseAttributes))
                continue
            }

            let targetIndex: Int
            if match.numberOfRanges > 1,
               match.range(at: 1).location != NSNotFound,
               let positionalRange = Range(match.range(at: 1), in: rawString),
               let parsedIndex = Int(rawString[positionalRange]),
               parsedIndex > 0 {
                targetIndex = parsedIndex - 1
            } else {
                targetIndex = argumentIndex
                argumentIndex += 1
            }

            if targetIndex < arguments.count {
                var formattedArg = arguments[targetIndex].resolveAttributedString(format: formatPiece, in: environment)
                formattedArg.mergeAttributes(baseAttributes, mergePolicy: .keepCurrent)
                result.append(formattedArg)
            } else {
                result.append(attributedString[attrMatchRange])
            }
        }

        if lastIndex < rawString.endIndex {
            if let tailAttrRange = Range(lastIndex..<rawString.endIndex, in: attributedString) {
                result.append(attributedString[tailAttrRange])
            }
        }

        attributedString = result
    }

    private func resolveArguments(
        in attributedString: NSMutableAttributedString,
        with arguments: [LocalizedTextArgument],
        environment: EnvironmentValues
    ) {
        let regex = formatArgumentRegex()
        let fullString = attributedString.string
        let fullRange = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: fullString, options: [], range: fullRange)

        guard !matches.isEmpty else { return }

        let result = NSMutableAttributedString()
        var lastLocation = 0
        var argumentIndex = 0

        for match in matches {
            let matchRange = match.range

            if matchRange.location > lastLocation {
                let pieceRange = NSRange(location: lastLocation, length: matchRange.location - lastLocation)
                result.append(attributedString.attributedSubstring(from: pieceRange))
            }

            lastLocation = matchRange.location + matchRange.length

            let currentAttributes = matchRange.location < attributedString.length
                ? attributedString.attributes(at: matchRange.location, effectiveRange: nil)
                : [:]

            let formatPiece = (fullString as NSString).substring(with: matchRange)
            if formatPiece == "%%" {
                result.append(NSAttributedString(string: "%", attributes: currentAttributes))
                continue
            }

            let targetIndex: Int
            if match.numberOfRanges > 1,
               match.range(at: 1).location != NSNotFound,
               let parsedIndex = Int((fullString as NSString).substring(with: match.range(at: 1))),
               parsedIndex > 0 {
                targetIndex = parsedIndex - 1
            } else {
                targetIndex = argumentIndex
                argumentIndex += 1
            }

            if targetIndex < arguments.count {
                let argument = arguments[targetIndex]
                let formattedArg = argument.resolveNSAttributedString(format: formatPiece, in: environment)

                let finalArg = NSMutableAttributedString(attributedString: formattedArg)
                if !currentAttributes.isEmpty {
                    finalArg.mergeAttributes(currentAttributes, keepCurrent: true)
                }
                result.append(finalArg)
            } else {
                result.append(attributedString.attributedSubstring(from: matchRange))
            }
        }

        if lastLocation < attributedString.length {
            let tailRange = NSRange(location: lastLocation, length: attributedString.length - lastLocation)
            result.append(attributedString.attributedSubstring(from: tailRange))
        }

        attributedString.setAttributedString(result)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class AttachmentTextStorage: ResolvedTextStorage {
    let image: Image

    init(image: Image) {
        self.image = image
    }

    func resolveIsEmpty() -> Bool {
        return false
    }

    func resolveHasAttributes() -> Bool {
        return true
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        let baselineOffset = attributes.baselineOffset
        let attributes = attributes.attributeContainer(in: environment)
        var attributedString = AttributedString(.attachment, attributes: attributes)
        var environment = environment
        if let font = attributes.swiftUI.font {
            environment.font = font
        }
        #if !os(watchOS)
        attributedString.attachment = resolveAttachment(
            in: environment,
            with: baselineOffset
        )
        #endif
        return attributedString
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        let baselineOffset = attributes.baselineOffset
        let attributes = attributes.attributes(in: environment)
        var environment = environment
        if let font = attributes[.font] as? Font.PlatformRepresentable {
            environment.font = Font(font)
        }
        let attachment = resolveAttachment(
            in: environment,
            with: baselineOffset
        )
        if let attachment {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return NSAttributedString(attachment: attachment, attributes: attributes)
            } else {
                let attributedString = NSMutableAttributedString(attachment: attachment)
                attributedString.setAttributes(
                    attributes,
                    range: NSRange(location: 0, length: attributedString.length)
                )
                return attributedString
            }
        }
        return NSAttributedString(string: .attachment, attributes: attributes)
    }

    func resolveAttachment(
        in environment: EnvironmentValues,
        with baselineOffset: CGFloat?
    ) -> NSTextAttachment? {
        #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
        if var image = image.toPlatformValue(in: environment) {
            #if os(iOS) || os(tvOS) || os(visionOS)
            var baselineOffset = baselineOffset
            if baselineOffset == nil, #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                baselineOffset = environment.baselineOffset
            }
            if let baselineOffset, baselineOffset != 0 {
                image = image.withBaselineOffset(fromBottom: baselineOffset)
            }
            let attachment = NSTextAttachment(image: image)
            #elseif os(macOS)
            let attachment = NSTextAttachment()
            attachment.image = image
            #endif
            return attachment
        }
        #endif
        return nil
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class AttributedStringTextStorage: ResolvedTextStorage {
    let attributedString: AttributedString

    init(attributedString: AttributedString) {
        self.attributedString = attributedString
    }

    func resolveIsEmpty() -> Bool {
        return attributedString.characters.isEmpty
    }

    func resolveHasAttributes() -> Bool {
        return attributedString.runs.allSatisfy { $0.attributes == AttributeContainer() }
    }

    func resolveAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> AttributedString {
        let attributedString = attributedString.mergingAttributes(
            attributes.attributeContainer(in: environment),
            mergePolicy: .keepCurrent
        )
        return attributedString
    }

    func resolveNSAttributedString(
        in environment: EnvironmentValues,
        with attributes: ResolvedTextAttributes
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            attributedString: attributedString.toNSAttributedString(in: environment)
        )
        attributedString.mergeAttributes(attributes.attributes(in: environment), keepCurrent: true)
        return attributedString
    }
}

extension LocalizedStringKey {

    var localizationKey: String {
        try! swift_getFieldValue("key", String.self, self)
    }
}

extension NSMutableAttributedString {

    func mergeAttributes(_ attributes: [NSAttributedString.Key: Any], keepCurrent: Bool) {
        let range = NSRange(location: 0, length: length)
        mergeAttributes(attributes, range: range, keepCurrent: keepCurrent)
    }

    func mergeAttributes(_ attributes: [NSAttributedString.Key: Any], range: NSRange, keepCurrent: Bool) {
        let range = NSRange(location: 0, length: length)
        enumerateAttributes(in: range) { currentAttributes, range, _ in
            var newAttributes: [NSAttributedString.Key: Any] = [:]
            for (key, value) in attributes {
                if currentAttributes[key] == nil {
                    newAttributes[key] = value
                }
            }
            if !newAttributes.isEmpty {
                addAttributes(newAttributes, range: range)
            }
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

    public func toNSLineBreakMode(lineLimit: Int?) -> NSLineBreakMode {
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
        lineBreakMode: NSLineBreakMode,
        minimumScaleFactor: CGFloat = 1,
        displayScale: CGFloat
    ) -> CGSize {
        guard length > 0 else { return .zero }

        #if os(watchOS)
        let context = NSStringDrawingContext()
        context.minimumScaleFactor = minimumScaleFactor
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
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
        let shouldScale = context.minimumScaleFactor < 1 && context.actualScaleFactor < 1
        let scale = context.actualScaleFactor
        #else
        let textContainer = NSTextContainer(size: size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = lineLimit ?? 0
        textContainer.lineBreakMode = lineBreakMode

        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = false
        let textStorage = NSTextStorage(attributedString: self)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        layoutManager.ensureLayout(for: textContainer)
        var sizeThatFits = layoutManager.usedRect(for: textContainer).size
        let shouldScale = minimumScaleFactor < 1 && sizeThatFits.width > size.width
        let scale = max(minimumScaleFactor, size.width / sizeThatFits.width)
        #endif

        if shouldScale {
            let mutableAttributedString = NSMutableAttributedString(attributedString: self)
            mutableAttributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
                guard let font = value as? Font.PlatformRepresentable else { return }
                let scaledFont = font.withSize(floor(font.pointSize * scale))
                mutableAttributedString.addAttribute(.font, value: scaledFont, range: range)
            }
            #if os(watchOS)
            sizeThatFits = mutableAttributedString.boundingRect(
                with: size,
                options: options,
                context: context
            ).size
            #else
            textStorage.setAttributedString(mutableAttributedString)
            layoutManager.ensureLayout(for: textContainer)
            sizeThatFits = layoutManager.usedRect(for: textContainer).size
            #endif
        }

        sizeThatFits.height = sizeThatFits.height.rounded(scale: displayScale)
        sizeThatFits.width = sizeThatFits.width.rounded(scale: displayScale)
        return sizeThatFits
    }
}

// MARK: - Previews

struct Text_Previews: PreviewProvider {

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    struct PreviewAttribute: TextAttributeKey {
        var value: Int
        static let name: String = "PreviewAttribute"
    }

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

            Text(prefix: .bulletPointSeparator, "Line 1")

            Text(separator: .dotSeparator) {
                Text("One")
                Text("Two")
            }

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Text(spaces: 100)
                    .redacted(reason: .placeholder)
            }

            let plainText = Text("Hello, World")
            HStack {
                Text(plainText.isAttributed ? "isAttributed" : "plain")

                plainText
            }

            let boldText = Text("Hello, World").fontWeight(.bold)
            HStack {
                Text(boldText.isAttributed ? "isAttributed" : "plain")

                boldText
            }

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                let boldSubText = Text("Hello, \(Text("World").fontWeight(.bold))")
                HStack {
                    Text(boldSubText.isAttributed ? "isAttributed" : "plain")

                    boldSubText
                }
            }

            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                let attributedString: Optional<AttributedString> = AttributedString("Hello, World")
                Text(attributedString)

                let number: Optional<Int> = 42
                Text(number, format: .number)

                let measurement: Optional<Measurement<UnitLength>> = Measurement(value: 1234, unit: .meters)
                Text(measurement, format: .measurement(width: .narrow))

                Text(measurement, format: .measurement(width: .narrow), unitsFont: .caption)

                Text(0.889, format: .percent, percentFont: .caption, decimalFont: .caption)

                Text(9.99, format: .currency(code: "CAD"), currencyFont: .headline, decimalFont: .caption)

                let attributes: AttributeContainer = {
                    var attributes = AttributeContainer()
                    attributes.swiftUI.font = .body.bold()
                    return attributes
                }()
                AttributedStringReader(
                    Text(AttributedString("Hello, World", attributes: attributes))
                    .foregroundColor(.red)
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("Hello, \(Text("World").fontWeight(.bold))")
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("Hello, \(AttributedString("World", attributes: attributes))")
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("**Hello, World**")
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("**Hello, \(1)**")
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("**Hello, \("Test")**")
                ) { attributedString in
                    Text(attributedString)
                }

                AttributedStringReader(
                    Text("**Hello, \(1, format: .number)**")
                ) { attributedString in
                    Text(attributedString)
                }
            }

            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                AttributedStringReader(
                    Text("Hello, World")
                        .customAttribute(PreviewAttribute(value: 1))
                ) { attributedString in
                    VStack {
                        Text(attributedString)

                        Text(attributedString.description)
                    }
                }

                AttributedStringReader(
                    Text("Hello, World")
                        .foregroundStyle(Color.red.gradient)
                ) { attributedString in
                    Text(attributedString)
                }
            }
        }
    }
}
