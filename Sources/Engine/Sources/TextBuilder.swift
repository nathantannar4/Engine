//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `[Text]` from closures.
@frozen
@resultBuilder
public struct TextBuilder {

    /// Builds an empty array from a block containing no statements.
    public static func buildBlock() -> [Text] { [] }

    /// Builds an empty array from a block containing only `Void` statements.
    public static func buildPartialBlock(first: Void) -> [Text] { [] }

    /// Builds an empty array from a block containing a `Never` statement.
    public static func buildPartialBlock(first: Never) -> [Text] {}

    /// Builds an array containing `component`, or an empty array if it is `nil`.
    public static func buildExpression(
        _ component: Text?
    ) -> [Text] {
        guard let component else { return [] }
        return [component]
    }

    /// Builds an array containing `component`.
    public static func buildExpression(
        _ component: Text
    ) -> [Text] {
        return [component]
    }

    /// Passes an array of texts through unmodified.
    public static func buildExpression(
        _ components: [Text]
    ) -> [Text] {
        components
    }

    /// Builds an array of the texts produced by each element of a `ForEach`.
    public static func buildExpression<
        Data: RandomAccessCollection,
        ID
    >(
        _ components: ForEach<Data, ID, Text>
    ) -> [Text] {
        components.data.map { components.content($0) }
    }

    /// Produces the texts for an `if` statement without an `else` branch,
    /// or an empty array when the condition is false.
    public static func buildIf(
        _ components: [Text]?
    ) -> [Text] {
        components ?? []
    }

    /// Produces content for a conditional statement when the condition is true.
    public static func buildEither(
        first: [Text]
    ) -> [Text] { first }

    /// Produces content for a conditional statement when the condition is false.
    public static func buildEither(
        second: [Text]
    ) -> [Text] {
        second
    }

    /// Flattens the texts produced by a `for` loop.
    public static func buildArray(
        _ components: [[Text]]
    ) -> [Text] {
        components.flatMap { $0 }
    }

    /// Builds an array containing the first text of a block.
    public static func buildPartialBlock(
        first: Text
    ) -> [Text] {
        [first]
    }

    /// Passes the first array of texts of a block through unmodified.
    public static func buildPartialBlock(
        first: [Text]
    ) -> [Text] {
        first
    }

    /// Appends the next text of a block to the accumulated texts.
    public static func buildPartialBlock(
        accumulated: [Text],
        next: Text
    ) -> [Text] {
        accumulated + [next]
    }

    /// Appends the next texts of a block to the accumulated texts.
    public static func buildPartialBlock(
        accumulated: [Text],
        next: [Text]
    ) -> [Text] {
        accumulated + next
    }

    /// Returns the built texts as an array.
    public static func buildFinalResult(_ components: [Text]) -> [Text] {
        return components
    }

    /// Returns the built texts joined by a space into a single text.
    public static func buildFinalResult(_ components: [Text]) -> Text {
        Text { components }
    }

    /// Returns the built texts joined by a space into a single text,
    /// or `nil` if there are no texts.
    public static func buildFinalResult(_ components: [Text]) -> Text? {
        guard !components.isEmpty else { return nil }
        return Text { components }
    }
}

/// A view that displays a list of texts joined by a separator.
///
/// Empty texts are omitted, and nothing is displayed when every text is empty.
/// When the view is redacted, the joined text is resolved and redacted as a whole.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct MultiText: View {

    /// The text inserted between each of the blocks.
    public var separator: Text
    /// The texts to join.
    public var blocks: [Text]

    /// Creates a view that joins the texts built by `blocks` with `separator`.
    @inlinable
    public init(
        separator: Text = .space,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.separator = separator
        self.blocks = blocks()
    }

    /// Creates a view that joins the texts built by `blocks` with a separator
    /// string displayed verbatim.
    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(
        separator: S,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    /// Creates a view that joins the texts built by `blocks` with a localized separator.
    @inlinable
    public init(
        separator: LocalizedStringKey,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    public var body: some View {
        MultiTextBody(separator: separator, blocks: blocks)
            .equatable()
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct MultiTextBody: View, Equatable {

    var separator: Text
    var blocks: [Text]

    var body: some View {
        ResolvedBody(separator: separator, blocks: blocks)
    }

    struct ResolvedBody: View {

        var separator: Text
        var blocks: [Text]

        @Environment(\.self) var environment

        var body: some View {
            if let text = blocks.joined(separator: separator) {
                environment.redactionReasons.isEmpty
                    ? text
                    : Text(text.resolve(in: environment))
            }
        }
    }
}

extension Text {

    /// Creates a text that joins the texts built by `blocks` with a separator
    /// string displayed verbatim. Empty texts are omitted.
    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(
        separator: S,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    /// Creates a text that joins the texts built by `blocks` with a localized
    /// separator. Empty texts are omitted.
    @inlinable
    public init(
        separator: LocalizedStringKey,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    /// Creates a text that joins the texts built by `blocks` with `separator`.
    /// Empty texts are omitted, and the result is empty if there are no texts.
    @inlinable
    public init(
        separator: Text = .space,
        @TextBuilder blocks: () -> [Text]
    ) {
        self = Text(joinedBy: separator, blocks: blocks) ?? Text(verbatim: "")
    }

    /// Creates a text that joins the texts built by `blocks` with `separator`,
    /// or `nil` if there are no non-empty texts.
    @inlinable
    public init?(
        joinedBy separator: Text,
        @TextBuilder blocks: () -> [Text]
    ) {
        guard let joined = blocks().joined(separator: separator) else { return nil }
        self = joined
    }
}

extension RandomAccessCollection where Element == Text {

    /// Returns the concatenation of the non-empty texts, inserting `separator`
    /// between each, or `nil` if there are no non-empty texts.
    public func joined(separator: Text) -> Text? {
        let elements = filter { !$0.isEmpty }
        switch elements.count {
        case 0:
            return nil

        case 1:
            return elements[0]

        default:
            return elements.dropFirst().reduce(into: elements[0]) { result, text in
                result = result + separator + text
            }
        }
    }
}

// MARK: - Previews

struct TextBuilder_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var flag = false

        func optionalText() -> Text? {
            Text("*")
        }

        @TextBuilder
        var texts: [Text] {
            if flag {
                Text("~")
            }

            Text("Hello")
                .font(.headline)
                .foregroundColor(.red)

            Text("World")
                .fontWeight(.light)

            if flag {
                Text("!")
            } else {
                Text(".")
            }

            optionalText()

            [Text("Line 1"), Text("Line 2")]

            for i in 1...3 {
                Text("Line \(i)")
            }

            ForEach(0..<3) { index in
                Text(index.description)
            }
        }

        @TextBuilder
        var combinedTexts: Text {
            texts
        }

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { Text("Flag") }

                Text {
                    // Empty
                }
                .frame(minWidth: 20)
                .border(Color.red)

                Text(joinedBy: .space) {
                    // Empty
                }
                .frame(minWidth: 20)
                .border(Color.red)

                Text("isEmpty: \(Text(verbatim: "").isEmpty.description)")

                Text(separator: Text(verbatim: " * ")) {
                    Text("1")
                    Text(verbatim: "") // Empty Filtered Out
                    Text("2")
                    Text(verbatim: "") // Empty Filtered Out
                    Text("3")
                }

                let text = Text {
                    texts
                }

                combinedTexts

                text

                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    text
                        .redacted(reason: .placeholder)

                    // This wont be rendered, since no text
                    MultiText {
                        // Empty
                    }
                    .frame(minWidth: 20)
                    .border(Color.red)

                    MultiText {
                        texts
                    }
                    .redacted(reason: flag ? [] : .placeholder)

                    Text("Value with interpolation: \(Text("Hello, World!"))")
                        .redacted(reason: .placeholder)

                    // Different underlying storage cause redacted differences
                    (Text("Line 1") + Text(verbatim: " ") + Text("Line 2"))
                        .redacted(reason: .placeholder)

                    (Text("Line 1") + Text(" ") + Text("Line 2"))
                        .redacted(reason: .placeholder)

                    Text("\(Text("Line 1")) \(Text("Line 2"))")
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}
