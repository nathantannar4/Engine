//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `[Text]` from closures.
@frozen
@resultBuilder
public struct TextBuilder {

    public static func buildBlock() -> [Text] { [] }

    public static func buildPartialBlock(
        first: Void
    ) -> [Text] { [] }

    public static func buildPartialBlock(
        first: Never
    ) -> [Text] {}

    public static func buildExpression(
        _ component: Text?
    ) -> [Text] {
        guard let component else { return []}
        return [component]
    }

    public static func buildExpression(
        _ components: [Text]
    ) -> [Text] {
        components
    }

    public static func buildExpression<
        Data: RandomAccessCollection,
        ID
    >(
        _ components: ForEach<Data, ID, Text>
    ) -> [Text] {
        components.data.map { components.content($0) }
    }

    public static func buildIf(
        _ components: [Text]?
    ) -> [Text] {
        components ?? []
    }

    public static func buildEither(
        first: [Text]
    ) -> [Text] { first }

    public static func buildEither(
        second: [Text]
    ) -> [Text] {
        second
    }

    public static func buildArray(
        _ components: [[Text]]
    ) -> [Text] {
        components.flatMap { $0 }
    }

    public static func buildPartialBlock(
        first: Text
    ) -> [Text] {
        [first]
    }

    public static func buildPartialBlock(
        first: [Text]
    ) -> [Text] {
        first
    }

    public static func buildPartialBlock(
        accumulated: [Text],
        next: Text
    ) -> [Text] {
        accumulated + [next]
    }

    public static func buildPartialBlock(
        accumulated: [Text],
        next: [Text]
    ) -> [Text] {
        accumulated + next
    }
}


@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct MultiText: View {

    public var separator: Text
    public var blocks: [Text]

    @Environment(\.self) private var environment

    @inlinable
    public init(
        separator: Text = Text(verbatim: " "),
        @TextBuilder blocks: () -> [Text]
    ) {
        self.separator = separator
        self.blocks = blocks()
    }

    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(
        separator: S,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    @inlinable
    public init(
        separator: LocalizedStringKey,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    public var body: some View {
        if let text = blocks.joined(separator: separator) {
            environment.redactionReasons.isEmpty
                ? text
                : Text(text.resolve(in: environment))
        }
    }
}


extension Text {

    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(
        separator: S,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    @inlinable
    public init(
        separator: LocalizedStringKey,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    @inlinable
    public init(
        separator: Text = Text(verbatim: " "),
        @TextBuilder blocks: () -> [Text]
    ) {
        self = blocks().joined(separator: separator) ?? Text(verbatim: "")
    }
}

extension RandomAccessCollection where Element == Text {

    public func joined(separator: Text) -> Text? {
        switch count {
        case 0:
            return nil

        case 1:
            return self[startIndex]

        default:
            return dropFirst().reduce(into: self[startIndex]) { result, text in
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

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { Text("Flag") }

                Text {
                    // Empty
                }
                .frame(minWidth: 20)
                .border(Color.red)

                let text = Text {
                    texts
                }

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
                    .redacted(reason: .placeholder)
                }
            }
        }
    }
}
