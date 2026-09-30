//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftUI

extension String {

    /// A single space character.
    public static let space: String = " "

    /// A blank Braille pattern character (U+2800) that renders as empty space
    /// but is not treated as whitespace by text layout.
    public static let lineWrappingSpace: String = "\u{2800}"

    /// Returns a string of `count` repeated ``lineWrappingSpace`` characters.
    public static func lineWrappingSpaces(_ count: Int) -> String {
        return String(repeating: lineWrappingSpace, count: count)
    }

    /// A middle dot separator surrounded by spaces.
    public static let dotSeparator: String = " · "

    /// An em dash separator surrounded by spaces.
    public static let dashSeparator: String = " — "

    /// A newline character.
    public static let newline: String = "\n"

    /// A bullet point followed by a space.
    public static let bulletPointSeparator: String = "• "

    /// A forward slash separator surrounded by spaces.
    public static let backSlashSeparator: String = " / "

    /// A horizontal ellipsis character.
    public static let ellipsis: String = "…"

    /// An SF Symbols glyph used as a placeholder character for redacted text.
    public static let redactedPlaceholder: String = "􀮷"

    /// Returns a string of `count` repeated ``redactedPlaceholder`` characters.
    public static func redactedPlaceholders(_ count: Int) -> String {
        return String(repeating: .redactedPlaceholder, count: count)
    }

    /// Returns a copy of the string with each character replaced by ``redactedPlaceholder``,
    /// or the string unchanged when `isRedacted` is `false`.
    public func redacted(_ isRedacted: Bool = true) -> String {
        guard isRedacted else { return self }
        return .redactedPlaceholders(count)
    }

    /// The object replacement character used to represent a text attachment.
    public static let attachment: String = {
        #if os(macOS)
        return "\u{FFFC}"
        #else
        return "\(Character(UnicodeScalar(NSTextAttachment.character)!))"
        #endif
    }()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AttributedString {

    /// Returns a copy of the attributed string with each character replaced by
    /// `String.redactedPlaceholder`, preserving the attributes of each run.
    /// Returns the string unchanged when `isRedacted` is `false`.
    public func redacted(_ isRedacted: Bool = true) -> AttributedString {
        guard isRedacted else { return self }
        var mutable = self
        for run in runs.reversed() {
            let redacted = String(self[run.range].characters).redacted()
            mutable.characters.replaceSubrange(run.range, with: redacted)
            mutable[run.range].setAttributes(run.attributes)
        }
        return mutable
    }
}

extension NSAttributedString {

    /// Returns the attributed string with each character replaced by
    /// `String.redactedPlaceholder`, preserving attributes.
    /// Returns the string unchanged when `isRedacted` is `false`.
    ///
    /// > Note: If the receiver is an `NSMutableAttributedString` it is redacted in place.
    public func redacted(_ isRedacted: Bool = true) -> NSAttributedString {
        guard isRedacted else { return self }
        if let mutableAttributedString = self as? NSMutableAttributedString {
            mutableAttributedString.redact()
            return mutableAttributedString
        } else {
            let mutableAttributedString = NSMutableAttributedString(attributedString: self)
            mutableAttributedString.redact()
            return mutableAttributedString
        }
    }
}

extension NSMutableAttributedString {

    /// Replaces each character with `String.redactedPlaceholder` in place, preserving attributes.
    public func redact() {
        let range = NSRange(location: 0, length: length)
        enumerateAttributes(in: range, options: .reverse) { attributes, range, _ in
            let redacted = attributedSubstring(from: range).string.redacted()
            replaceCharacters(
                in: range,
                with: NSAttributedString(string: redacted, attributes: attributes)
            )
        }
    }
}
