//
// Copyright (c) Nathan Tannar
//

import Foundation
import SwiftUI

extension String {

    public static let space: String = " "

    public static let lineWrappingSpace: String = "\u{2800}"

    public static func lineWrappingSpaces(_ count: Int) -> String {
        return String(repeating: lineWrappingSpace, count: count)
    }

    public static let dotSeparator: String = " · "

    public static let dashSeparator: String = " — "

    public static let newline: String = "\n"

    public static let bulletPointSeparator: String = "• "

    public static let backSlashSeparator: String = " / "

    public static let ellipsis: String = "…"

    public static let redactedPlaceholder: String = "􀮷"

    public static func redactedPlaceholders(_ count: Int) -> String {
        return String(repeating: .redactedPlaceholder, count: count)
    }

    public func redacted(_ isRedacted: Bool = true) -> String {
        guard isRedacted else { return self }
        return .redactedPlaceholders(count)
    }

    public static let attachment: String = {
        #if os(macOS)
        return "\u{FFFC}"
        #else
        return "\(Character(UnicodeScalar(NSTextAttachment.character)!))"
        #endif
    }()
}

extension AttributedString {

    public func redacted(_ isRedacted: Bool = true) -> AttributedString {
        guard isRedacted else { return self }
        var mutable = self
        for run in runs.reversed() {
            #if !os(watchOS)
            // Attachments are not redacted, consistent with `Text` concatenation
            if run.attachment != nil { continue }
            #endif
            let redacted = String(self[run.range].characters).redacted()
            mutable.characters.replaceSubrange(run.range, with: redacted)
            mutable[run.range].setAttributes(run.attributes)
        }
        return mutable
    }
}

extension NSAttributedString {

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

    public func redact() {
        let range = NSRange(location: 0, length: length)
        enumerateAttributes(in: range, options: .reverse) { attributes, range, _ in
            // Attachments are not redacted, consistent with `Text` concatenation
            guard attributes[.attachment] == nil else { return }
            let redacted = attributedSubstring(from: range).string.redacted()
            replaceCharacters(
                in: range,
                with: NSAttributedString(string: redacted, attributes: attributes)
            )
        }
    }
}
