//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AttributedString {

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `AttributedString` attributes to their UIKit equivalent
    public func toUIKit(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> AttributedString {
        var result = self
        for run in result.runs {
            result[run.range].setAttributes(run.attributes.toUIKit(in: environment))
        }
        return result
    }
    #elseif os(macOS)
    /// Transforms SwiftUI `AttributedString` attributes to their AppKit equivalent
    public func toAppKit(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> AttributedString {
        var result = self
        for run in result.runs {
            result[run.range].setAttributes(run.attributes.toAppKit(in: environment))
        }
        return result
    }
    #endif
}

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension AttributedString {

    #if os(macOS) || os(iOS) || os(visionOS) || os(tvOS)
    public init<Content: View>(
        attachment: Content
    ) {
        self = .attachment
        self.attachment = HostingTextAttachment(content: attachment)
    }
    #endif

    static let attachment: AttributedString = {
        AttributedString("\(Character(UnicodeScalar(NSTextAttachment.character)!))")
    }()
}

#if os(macOS) || os(iOS) || os(visionOS) || os(tvOS)

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, *)
private class HostingTextAttachment<Content: View>: NSTextAttachment, @unchecked Sendable {

    let content: Content

    init(content: Content) {
        self.content = content
        super.init(data: nil, ofType: nil)
        allowsTextAttachmentView = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var usesTextAttachmentView: Bool { true }

    #if os(macOS)
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        return HostingTextAttachmentViewProvider(
            attachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
    #else
    override func viewProvider(
        for parentView: UIView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        return HostingTextAttachmentViewProvider(
            attachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
    #endif
}

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, *)
private class HostingTextAttachmentViewProvider<Content: View>: NSTextAttachmentViewProvider {

    let attachment: HostingTextAttachment<Content>

    #if os(macOS)
    init(
        attachment: HostingTextAttachment<Content>,
        parentView: NSView?,
        textLayoutManager: NSTextLayoutManager?,
        location: any NSTextLocation
    ) {
        self.attachment = attachment
        super.init(
            textAttachment: attachment,
            parentView: parentView,
            textLayoutManager: textLayoutManager,
            location: location
        )
    }
    #else
    init(
        attachment: HostingTextAttachment<Content>,
        parentView: UIView?,
        textLayoutManager: NSTextLayoutManager?,
        location: any NSTextLocation
    ) {
        self.attachment = attachment
        super.init(
            textAttachment: attachment,
            parentView: parentView,
            textLayoutManager: textLayoutManager,
            location: location
        )
    }
    #endif

    override func loadView() {
        let content = attachment.content
        view = MainActor.assumeIsolated {
            HostingView(content: content)
        }
    }
}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AttributeContainer {

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// Transforms SwiftUI `AttributedString` attributes to their UIKit equivalent
    public func toUIKit(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> AttributeContainer {
        var attributes = self
        if let font = attributes.swiftUI.font, attributes.uiKit.font == nil {
            attributes.uiKit.font = font.toUIFont()
        }
        if let foregroundColor = attributes.swiftUI.foregroundColor, attributes.uiKit.foregroundColor == nil {
            attributes.uiKit.foregroundColor = foregroundColor.toUIColor()
        }
        if let backgroundColor = attributes.swiftUI.backgroundColor, attributes.uiKit.backgroundColor == nil {
            attributes.uiKit.backgroundColor = backgroundColor.toUIColor()
        }
        if let strikethroughStyle = attributes.swiftUI.strikethroughStyle {
            attributes.uiKit.strikethroughStyle = NSUnderlineStyle(strikethroughStyle)
            let color = Mirror(reflecting: strikethroughStyle).descendant("color") as? Color
            if let color {
                attributes.uiKit.strikethroughColor = color.toUIColor()
            }
        }
        if let underlineStyle = attributes.swiftUI.underlineStyle {
            attributes.uiKit.underlineStyle = NSUnderlineStyle(underlineStyle)
            let color = Mirror(reflecting: underlineStyle).descendant("color") as? Color
            if let color {
                attributes.uiKit.underlineColor = color.toUIColor()
            }
        }
        if let kern = attributes.swiftUI.kern {
            attributes.uiKit.kern = kern
        }
        if let tracking = attributes.swiftUI.tracking {
            attributes.uiKit.tracking = tracking
        }
        if let baselineOffset = attributes.swiftUI.baselineOffset {
            attributes.uiKit.baselineOffset = baselineOffset
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = environment.lineSpacing
        attributes.uiKit.paragraphStyle = paragraphStyle
        return attributes
    }
    #elseif os(macOS)
    /// Transforms SwiftUI `AttributedString` attributes to their AppKit equivalent
    public func toAppKit(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> AttributeContainer {
        var attributes = self
        if let font = attributes.swiftUI.font, attributes.appKit.font == nil {
            attributes.appKit.font = font.toNSFont()
        }
        if let foregroundColor = attributes.swiftUI.foregroundColor, attributes.appKit.foregroundColor == nil {
            attributes.appKit.foregroundColor = foregroundColor.toNSColor()
        }
        if let backgroundColor = attributes.swiftUI.backgroundColor, attributes.appKit.backgroundColor == nil {
            attributes.appKit.backgroundColor = backgroundColor.toNSColor()
        }
        if let strikethroughStyle = attributes.swiftUI.strikethroughStyle {
            attributes.appKit.strikethroughStyle = NSUnderlineStyle(strikethroughStyle)
            let color = Mirror(reflecting: strikethroughStyle).descendant("color") as? Color
            if let color {
                attributes.appKit.strikethroughColor = color.toNSColor()
            }
        }
        if let underlineStyle = attributes.swiftUI.underlineStyle {
            attributes.appKit.underlineStyle = NSUnderlineStyle(underlineStyle)
            let color = Mirror(reflecting: underlineStyle).descendant("color") as? Color
            if let color {
                attributes.appKit.underlineColor = color.toNSColor()
            }
        }
        if let kern = attributes.swiftUI.kern {
            attributes.appKit.kern = kern
        }
        if let tracking = attributes.swiftUI.tracking {
            attributes.appKit.tracking = tracking
        }
        if let baselineOffset = attributes.swiftUI.baselineOffset {
            attributes.appKit.baselineOffset = baselineOffset
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = environment.lineSpacing
        attributes.appKit.paragraphStyle = paragraphStyle
        return attributes
    }
    #endif
}

#if hasAttribute(retroactive)
extension NSParagraphStyle: @unchecked @retroactive Sendable { }

#if os(macOS)
extension NSFont: @unchecked @retroactive Sendable { }
#endif
#else
extension NSParagraphStyle: @unchecked Sendable { }

#if os(macOS)
extension NSFont: @unchecked Sendable { }
#endif
#endif
