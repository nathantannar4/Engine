//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
final class TextTests: XCTestCase {

    let environment = EnvironmentValues()

    func testVerbatim() {
        XCTAssertEqual(Text(verbatim: "Hello").verbatim, "Hello")
        XCTAssert(Text(verbatim: "Hello").isVerbatim)
        XCTAssertEqual(Text("Hello" as String).verbatim, "Hello")
        XCTAssertNil(Text("Hello" as LocalizedStringKey).verbatim)
        XCTAssertFalse(Text("Hello" as LocalizedStringKey).isVerbatim)
        XCTAssertNil((Text(verbatim: "a") + Text(verbatim: "b")).verbatim)
        // Modifiers do not change the storage
        XCTAssertEqual(Text(verbatim: "Hello").bold().verbatim, "Hello")
    }

    func testIsEmpty() {
        XCTAssert(Text(verbatim: "").isEmpty)
        XCTAssert((Text(verbatim: "") + Text(verbatim: "")).isEmpty)
        XCTAssertFalse(Text(verbatim: " ").isEmpty)
        XCTAssertFalse(Text("Hello" as LocalizedStringKey).isEmpty)
        XCTAssertFalse((Text(verbatim: "") + Text(verbatim: "a")).isEmpty)
        XCTAssertFalse((Text(verbatim: "a") + Text(verbatim: "")).isEmpty)
    }

    func testIsAttributed() {
        XCTAssertFalse(Text(verbatim: "Hello").isAttributed)
        XCTAssertFalse(Text("Hello" as LocalizedStringKey).isAttributed)
        XCTAssert(Text(verbatim: "Hello").bold().isAttributed)
        XCTAssert(Text(verbatim: "Hello").italic().isAttributed)
        XCTAssert(Text(verbatim: "Hello").font(.body).isAttributed)
        XCTAssert(Text(verbatim: "Hello").foregroundColor(.red).isAttributed)
        XCTAssert(Text(verbatim: "Hello").kerning(1).isAttributed)
        XCTAssert(Text(verbatim: "Hello").baselineOffset(1).isAttributed)
        // `nil` values do not apply any styling
        XCTAssertFalse(Text(verbatim: "Hello").font(nil).isAttributed)
        XCTAssertFalse(Text(verbatim: "Hello").foregroundColor(nil).isAttributed)
        XCTAssertFalse(Text(verbatim: "Hello").fontWeight(nil).isAttributed)
        // Attributes on either side of a concatenation are detected
        XCTAssert((Text(verbatim: "a") + Text(verbatim: "b").bold()).isAttributed)
        XCTAssert((Text(verbatim: "a").bold() + Text(verbatim: "b")).isAttributed)
        XCTAssertFalse((Text(verbatim: "a") + Text(verbatim: "b")).isAttributed)
    }

    func testResolve() {
        XCTAssertEqual(Text(verbatim: "Hello").resolve(in: environment), "Hello")
        XCTAssertEqual(Text("Hello" as LocalizedStringKey).resolve(in: environment), "Hello")
        XCTAssertEqual((Text(verbatim: "Hello") + Text(", World")).resolve(in: environment), "Hello, World")
        XCTAssertEqual(Text("Count \(42)").resolve(in: environment), "Count 42")
        XCTAssertEqual(Text("Name \("Engine")").resolve(in: environment), "Name Engine")
        XCTAssertEqual(Text("\(Text("a")) \(Text(verbatim: "b"))").resolve(in: environment), "a b")
        XCTAssertEqual(Text(verbatim: "Hello").bold().resolve(in: environment), "Hello")
        XCTAssertEqual(Text.lineWrappingSpaces(3).resolve(in: environment), String(repeating: "\u{2800}", count: 3))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testResolveFormat() {
        var environment = environment
        environment.locale = Locale(identifier: "en_US")
        let format = IntegerFormatStyle<Int>().grouping(.never).locale(environment.locale)
        XCTAssertEqual(Text(1000, format: format).resolve(in: environment), "1000")
        XCTAssertEqual(Text(Optional(7), format: format)?.resolve(in: environment), "7")
        XCTAssertNil(Text(Optional<Int>.none, format: format))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testResolveAttributed() {
        let plain = Text(verbatim: "Hello").resolveAttributed(in: environment) as AttributedString
        XCTAssertEqual(String(plain.characters), "Hello")

        let concatenated = (Text(verbatim: "Hello") + Text(verbatim: " ") + Text("World").bold())
            .resolveAttributed(in: environment) as AttributedString
        XCTAssertEqual(String(concatenated.characters), "Hello World")

        let nsString = (Text(verbatim: "Hello") + Text("World"))
            .resolveAttributed(in: environment) as NSAttributedString
        XCTAssertEqual(nsString.string, "HelloWorld")
    }

    func testSeparators() {
        XCTAssertEqual(Text.space.resolve(in: environment), " ")
        XCTAssertEqual(Text.dotSeparator.resolve(in: environment), " · ")
        XCTAssertEqual(Text.dashSeparator.resolve(in: environment), " — ")
        XCTAssertEqual(Text.newline.resolve(in: environment), "\n")
        XCTAssertEqual(Text.bulletPointSeparator.resolve(in: environment), "• ")
        XCTAssertEqual(Text.backSlashSeparator.resolve(in: environment), " / ")
        XCTAssertEqual(Text.ellipsis.resolve(in: environment), "…")
    }

    func testPrefixSuffix() {
        XCTAssertEqual(Text(prefix: .ellipsis, Text(verbatim: "a")).resolve(in: environment), "…a")
        XCTAssertEqual(Text(prefix: .ellipsis, "a").resolve(in: environment), "…a")
        XCTAssertEqual(Text(Text(verbatim: "a"), suffix: .ellipsis).resolve(in: environment), "a…")
        XCTAssertEqual(Text("a", suffix: .ellipsis).resolve(in: environment), "a…")
    }

    func testOptionalInitializers() {
        XCTAssertNil(Text(Optional<String>.none))
        XCTAssertNil(Text(Optional<String>.some("")))
        XCTAssertEqual(Text(Optional<String>.some("a"))?.resolve(in: environment), "a")
        XCTAssertNil(Text(Optional<LocalizedStringKey>.none))
        XCTAssertEqual(Text(Optional<LocalizedStringKey>.some("a"))?.resolve(in: environment), "a")
        XCTAssertNil(Text(Optional<Image>.none))
        XCTAssertNotNil(Text(Optional<Image>.some(Image(systemName: "star"))))
        XCTAssertNil(Text(Optional<Date>.none, style: .date))
        XCTAssertNil(Text(Optional<ClosedRange<Date>>.none))
        XCTAssertNil(Text(Optional<DateInterval>.none))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testOptionalAttributedStringInitializer() {
        XCTAssertNil(Text(Optional<AttributedString>.none))
        XCTAssertNil(Text(Optional(AttributedString())))
        XCTAssertEqual(Text(Optional(AttributedString("a")))?.resolve(in: environment), "a")
    }

    func testAttachment() {
        XCTAssertNil(Text(verbatim: "a").attachment)
        XCTAssertNotNil(Text(Image(systemName: "star")).attachment)
        XCTAssert(Text(Image(systemName: "star")).isAttributed)
        XCTAssertFalse(Text(Image(systemName: "star")).isEmpty)
    }

    func testResolveAttachment() {
        let star = Image(systemName: "star")
        XCTAssertEqual(Text(star).resolve(in: environment), "\u{FFFC}")
        XCTAssertEqual((Text(verbatim: "a") + Text(star) + Text(verbatim: "b")).resolve(in: environment), "a\u{FFFC}b")
        XCTAssertEqual(Text("Rate \(star)").resolve(in: environment), "Rate \u{FFFC}")
        XCTAssertEqual(Text("Rate \(Text(star))").resolve(in: environment), "Rate \u{FFFC}")
    }

    #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
    func testResolveAttachmentNSAttributedString() {
        let star = Image(systemName: "star")

        let plain = Text(star).resolveNSAttributedString(in: environment)
        XCTAssertEqual(plain.string, "\u{FFFC}")
        XCTAssertNotNil(attachment(of: plain, at: 0)?.image)

        let concatenated = (Text(verbatim: "a") + Text(star) + Text(verbatim: "b"))
            .resolveNSAttributedString(in: environment)
        XCTAssertEqual(concatenated.string, "a\u{FFFC}b")
        XCTAssertNil(attachment(of: concatenated, at: 0))
        XCTAssertNotNil(attachment(of: concatenated, at: 1)?.image)
        XCTAssertNil(attachment(of: concatenated, at: 2))

        // Interpolated images resolve to an attachment at the argument position
        for text in [Text("Rate \(star)"), Text("Rate \(Text(star))")] {
            let interpolated = text.resolveNSAttributedString(in: environment)
            XCTAssertEqual(interpolated.string, "Rate \u{FFFC}")
            XCTAssertNil(attachment(of: interpolated, at: 0))
            XCTAssertNotNil(attachment(of: interpolated, at: 5)?.image)
        }

        // Modifiers apply to the attachment run
        let styled = Text(star).foregroundColor(.red).resolveNSAttributedString(in: environment)
        XCTAssertNotNil(attachment(of: styled, at: 0))
        XCTAssertNotNil(styled.attribute(.foregroundColor, at: 0, effectiveRange: nil))
        XCTAssertNotNil(styled.attribute(.font, at: 0, effectiveRange: nil))

        // Images that cannot be resolved fall back to the attachment character
        let missing = Text(Image("does-not-exist")).resolveNSAttributedString(in: environment)
        XCTAssertEqual(missing.string, "\u{FFFC}")
        XCTAssertNil(attachment(of: missing, at: 0))
    }

    func testResolveAttachmentFont() {
        let star = Image(systemName: "star")
        func imageSize(_ text: Text) -> CGSize? {
            attachment(of: text.resolveNSAttributedString(in: environment), at: 0)?.image?.size
        }
        guard
            let small = imageSize(Text(star).font(.caption)),
            let large = imageSize(Text(star).font(.largeTitle))
        else {
            return XCTFail("Missing attachment image")
        }
        XCTAssertGreaterThan(large.height, small.height)
        XCTAssertGreaterThan(large.width, small.width)

        let size = Text(star).font(.largeTitle).sizeThatFits(.unspecified, environment: environment)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    func testResolveAttachmentAttributedString() {
        let star = Image(systemName: "star")
        let concatenated = (Text(verbatim: "a") + Text(star) + Text(verbatim: "b")).foregroundColor(.red)
            .resolveAttributedString(in: environment)
        XCTAssertEqual(String(concatenated.characters), "a\u{FFFC}b")
        XCTAssertEqual(concatenated.runs.count, 3)
        XCTAssertEqual(concatenated.runs.map { $0.attachment != nil }, [false, true, false])
        for run in concatenated.runs {
            XCTAssertEqual(run.swiftUI.foregroundColor, .red)
        }

        let interpolated = Text("Rate \(star)").resolveAttributedString(in: environment)
        XCTAssertEqual(String(interpolated.characters), "Rate \u{FFFC}")
        XCTAssertEqual(interpolated.runs.map { $0.attachment != nil }, [false, true])
    }

    private func attachment(of attributedString: NSAttributedString, at index: Int) -> NSTextAttachment? {
        attributedString.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment
    }
    #endif

    func testTruncationModeLineBreakMode() {
        XCTAssertEqual(Text.TruncationMode.tail.toNSLineBreakMode(lineLimit: 1), .byTruncatingTail)
        XCTAssertEqual(Text.TruncationMode.head.toNSLineBreakMode(lineLimit: 2), .byTruncatingHead)
        XCTAssertEqual(Text.TruncationMode.middle.toNSLineBreakMode(lineLimit: 1), .byTruncatingMiddle)
        // Without a positive line limit the text wraps rather than truncates
        XCTAssertEqual(Text.TruncationMode.tail.toNSLineBreakMode(lineLimit: nil), .byWordWrapping)
        XCTAssertEqual(Text.TruncationMode.tail.toNSLineBreakMode(lineLimit: 0), .byWordWrapping)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testRedactedResolution() {
        XCTAssertEqual("Hello, World".redacted(), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        var environment = EnvironmentValues()
        environment.redactionReasons = .placeholder

        XCTAssertEqual(Text(verbatim: "Hello, World").resolve(in: environment), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("Hello, World").resolve(in: environment), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("\(Text("Hello, World"))").resolve(in: environment), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")

        XCTAssertEqual(Text(verbatim: "Hello, World").resolveNSAttributedString(in: environment).string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("Hello, World").resolveNSAttributedString(in: environment).string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("\(Text("Hello, World"))").resolveNSAttributedString(in: environment).string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("Hello, \("World")").resolveNSAttributedString(in: environment).string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(Text("Count \(42)").resolveNSAttributedString(in: environment).string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            XCTAssertEqual(String(Text(verbatim: "Hello, World").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
            XCTAssertEqual(String(Text("Hello, World").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
            XCTAssertEqual(String(Text("\(Text("Hello, World"))").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
            XCTAssertEqual(String(Text("Hello, \("World")").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
            XCTAssertEqual(String(Text("Count \(42)").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
            XCTAssertEqual(String(Text("**Hello**, World").resolveAttributedString(in: environment).characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        }

        // Image attachments are not redacted
        let star = Image(systemName: "star")
        XCTAssertEqual(Text(star).resolve(in: environment), "\u{FFFC}")
        XCTAssertEqual((Text(verbatim: "a") + Text(star) + Text(verbatim: "b")).resolve(in: environment), "􀮷\u{FFFC}􀮷")
        XCTAssertEqual(Text("Rate \(star)").resolve(in: environment), "􀮷􀮷􀮷􀮷􀮷\u{FFFC}")
        XCTAssertEqual(Text("Rate \(Text(star))").resolve(in: environment), "􀮷􀮷􀮷􀮷􀮷\u{FFFC}")

        #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
        XCTAssertEqual(Text(star).resolveNSAttributedString(in: environment).string, "\u{FFFC}")
        XCTAssertEqual((Text(verbatim: "a") + Text(star) + Text(verbatim: "b")).resolveNSAttributedString(in: environment).string, "􀮷\u{FFFC}􀮷")
        for text in [Text("Rate \(star)"), Text("Rate \(Text(star))")] {
            let interpolated = text.resolveNSAttributedString(in: environment)
            XCTAssertEqual(interpolated.string, "􀮷􀮷􀮷􀮷􀮷\u{FFFC}")
            XCTAssertNotNil(interpolated.attribute(.attachment, at: interpolated.length - 1, effectiveRange: nil))
        }

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
            XCTAssertEqual(String(Text(star).resolveAttributedString(in: environment).characters), "\u{FFFC}")
            XCTAssertEqual(String((Text(verbatim: "a") + Text(star) + Text(verbatim: "b")).resolveAttributedString(in: environment).characters), "􀮷\u{FFFC}􀮷")
            for text in [Text("Rate \(star)"), Text("Rate \(Text(star))")] {
                let interpolated = text.resolveAttributedString(in: environment)
                XCTAssertEqual(String(interpolated.characters), "􀮷􀮷􀮷􀮷􀮷\u{FFFC}")
                XCTAssertEqual(interpolated.runs.map { $0.attachment != nil }, [false, true])
            }
        }
        #endif
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testRedactedResolutionPreservesAttributes() {
        var environment = EnvironmentValues()
        environment.redactionReasons = .placeholder

        let markdown = Text("**Hello**, World").foregroundColor(.red)
            .resolveAttributedString(in: environment)
        XCTAssertEqual(String(markdown.characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertEqual(markdown.runs.count, 2)
        for run in markdown.runs {
            XCTAssertEqual(run.swiftUI.foregroundColor, .red)
        }
        let bold = markdown.runs.first!
        XCTAssertEqual(bold.inlinePresentationIntent, .stronglyEmphasized)
        XCTAssertEqual(markdown[bold.range].characters.count, 5)
        XCTAssertNil(markdown.runs.last!.inlinePresentationIntent)

        let interpolated = Text("Hello, \(Text("World").underline())").foregroundColor(.red)
            .resolveAttributedString(in: environment)
        XCTAssertEqual(String(interpolated.characters), "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        for run in interpolated.runs {
            XCTAssertEqual(run.swiftUI.foregroundColor, .red)
        }
        let underlined = interpolated.runs.filter { $0.swiftUI.underlineStyle != nil }
        XCTAssertEqual(underlined.map { interpolated[$0.range].characters.count }.reduce(0, +), 5)

        let nsMarkdown = Text("**Hello**, World").foregroundColor(.red)
            .resolveNSAttributedString(in: environment)
        XCTAssertEqual(nsMarkdown.string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        let firstIndex = 0
        let lastIndex = nsMarkdown.length - 1
        XCTAssertNotNil(nsMarkdown.attribute(.foregroundColor, at: firstIndex, effectiveRange: nil))
        XCTAssertNotNil(nsMarkdown.attribute(.foregroundColor, at: lastIndex, effectiveRange: nil))
        var boldRange = NSRange()
        XCTAssertNotNil(nsMarkdown.attribute(.inlinePresentationIntent, at: firstIndex, effectiveRange: &boldRange))
        XCTAssertEqual(boldRange, NSRange(location: 0, length: ("􀮷􀮷􀮷􀮷􀮷" as NSString).length))
        XCTAssertNil(nsMarkdown.attribute(.inlinePresentationIntent, at: lastIndex, effectiveRange: nil))
        XCTAssertTrue(fontTraits(of: nsMarkdown, at: firstIndex).contains(.traitBold))
        XCTAssertFalse(fontTraits(of: nsMarkdown, at: lastIndex).contains(.traitBold))

        let nsInterpolated = Text("Hello, \(Text("World").underline())").foregroundColor(.red)
            .resolveNSAttributedString(in: environment)
        XCTAssertEqual(nsInterpolated.string, "􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷􀮷")
        XCTAssertNotNil(nsInterpolated.attribute(.foregroundColor, at: 0, effectiveRange: nil))
        XCTAssertNil(nsInterpolated.attribute(.underlineStyle, at: 0, effectiveRange: nil))
        XCTAssertNotNil(nsInterpolated.attribute(.underlineStyle, at: nsInterpolated.length - 1, effectiveRange: nil))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testMarkdownNSAttributedStringFonts() {
        let ns = Text("**Bold** *Italic* ***Both*** `Code` ~~Strike~~ Plain")
            .resolveNSAttributedString(in: environment)
        let string = ns.string as NSString
        func location(of substring: String) -> Int {
            string.range(of: substring).location
        }
        XCTAssertTrue(fontTraits(of: ns, at: location(of: "Bold")).contains(.traitBold))
        XCTAssertFalse(fontTraits(of: ns, at: location(of: "Bold")).contains(.traitItalic))
        XCTAssertTrue(fontTraits(of: ns, at: location(of: "Italic")).contains(.traitItalic))
        XCTAssertFalse(fontTraits(of: ns, at: location(of: "Italic")).contains(.traitBold))
        XCTAssertTrue(fontTraits(of: ns, at: location(of: "Both")).isSuperset(of: [.traitBold, .traitItalic]))
        XCTAssertTrue(fontTraits(of: ns, at: location(of: "Code")).contains(.traitMonoSpace))
        XCTAssertNotNil(ns.attribute(.strikethroughStyle, at: location(of: "Strike"), effectiveRange: nil))
        XCTAssertNil(ns.attribute(.strikethroughStyle, at: location(of: "Plain"), effectiveRange: nil))
        XCTAssertTrue(fontTraits(of: ns, at: location(of: "Plain")).isDisjoint(with: [.traitBold, .traitItalic, .traitMonoSpace]))
    }

    private func fontTraits(of attributedString: NSAttributedString, at index: Int) -> CTFontSymbolicTraits {
        guard let font = attributedString.attribute(.font, at: index, effectiveRange: nil) as? Font.PlatformRepresentable else {
            XCTFail("Missing font at \(index)")
            return []
        }
        return CTFontGetSymbolicTraits(font)
    }

    // MARK: - TextBuilder

    @TextBuilder
    func texts(flag: Bool, optional: Text?, count: Int) -> [Text] {
        if flag {
            Text(verbatim: "if")
        }
        Text(verbatim: "a")
        if flag {
            Text(verbatim: "first")
        } else {
            Text(verbatim: "second")
        }
        optional
        [Text(verbatim: "b"), Text(verbatim: "c")]
        for i in 0..<count {
            Text(verbatim: "\(i)")
        }
        ForEach(0..<count, id: \.self) { i in
            Text(verbatim: "e\(i)")
        }
    }

    func testTextBuilder() {
        func resolve(_ texts: [Text]) -> [String] {
            texts.map { $0.resolve(in: environment) }
        }
        XCTAssertEqual(
            resolve(texts(flag: true, optional: Text(verbatim: "?"), count: 2)),
            ["if", "a", "first", "?", "b", "c", "0", "1", "e0", "e1"]
        )
        XCTAssertEqual(
            resolve(texts(flag: false, optional: nil, count: 0)),
            ["a", "second", "b", "c"]
        )
    }

    func testTextBuilderFinalResults() {
        @TextBuilder
        func empty() -> [Text] { }
        XCTAssert(empty().isEmpty)

        @TextBuilder
        func optionalText(_ include: Bool) -> Text? {
            if include {
                Text(verbatim: "a")
            }
        }
        XCTAssertNil(optionalText(false))
        XCTAssertEqual(optionalText(true)?.resolve(in: environment), "a")

        @TextBuilder
        func text() -> Text {
            Text(verbatim: "a")
            Text(verbatim: "b")
        }
        XCTAssertEqual(text().resolve(in: environment), "a b")
    }

    func testJoined() {
        XCTAssertNil([Text]().joined(separator: .space))
        XCTAssertNil([Text(verbatim: ""), Text(verbatim: "")].joined(separator: .space))
        XCTAssertEqual([Text(verbatim: "a")].joined(separator: .space)?.resolve(in: environment), "a")
        XCTAssertEqual(
            [Text(verbatim: "a"), Text(verbatim: "b"), Text(verbatim: "c")]
                .joined(separator: .dotSeparator)?
                .resolve(in: environment),
            "a · b · c"
        )
        // Empty text is skipped so that separators are not doubled
        XCTAssertEqual(
            [Text(verbatim: ""), Text(verbatim: "a"), Text(verbatim: ""), Text(verbatim: "b")]
                .joined(separator: Text(verbatim: ","))?
                .resolve(in: environment),
            "a,b"
        )
    }

    func testTextSeparatorBlocks() {
        XCTAssertEqual(Text { }.resolve(in: environment), "")
        XCTAssertNil(Text(joinedBy: .space) { })
        XCTAssertEqual(
            Text(separator: ", ") {
                Text(verbatim: "a")
                Text(verbatim: "b")
            }.resolve(in: environment),
            "a, b"
        )
        XCTAssertEqual(
            Text(joinedBy: .newline) {
                Text(verbatim: "a")
                Text(verbatim: "b")
            }?.resolve(in: environment),
            "a\nb"
        )
    }
}
