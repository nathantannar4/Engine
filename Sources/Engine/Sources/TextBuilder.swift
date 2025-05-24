//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `[Text]` from closures.
@frozen
@resultBuilder
public struct TextBuilder {

    @inlinable
    public static func buildBlock() -> [Optional<Text>] {
        []
    }

    @inlinable
    public static func buildPartialBlock(
        first: [Optional<Text>]
    ) -> [Optional<Text>] {
        first
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: [Optional<Text>],
        next: [Optional<Text>]
    ) -> [Optional<Text>] {
        accumulated + next
    }

    @inlinable
    public static func buildExpression(
        _ expression: Text
    ) -> [Optional<Text>] {
        [expression]
    }

    @inlinable
    public static func buildEither(
        first component: [Optional<Text>]
    ) -> [Optional<Text>] {
        component
    }

    @inlinable
    public static func buildEither(
        second component: [Optional<Text>]
    ) -> [Optional<Text>] {
        component
    }

    @inlinable
    public static func buildOptional(
        _ component: [Optional<Text>]?
    ) -> [Optional<Text>] {
        component ?? []
    }

    @inlinable
    public static func buildLimitedAvailability(
        _ component: [Optional<Text>]
    ) -> [Optional<Text>] {
        component
    }

    @inlinable
    public static func buildArray(
        _ components: [Optional<Text>]
    ) -> [Optional<Text>] {
        components
    }

    @inlinable
    public static func buildBlock(
        _ components: [Optional<Text>]...
    ) -> [Optional<Text>] {
        components.flatMap { $0 }
    }

    public static func buildFinalResult(
        _ component: [Optional<Text>]
    ) -> [Text] {
        component.compactMap { $0 }
    }
}


extension Text {

    @inlinable
    public init(
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(verbatim: " "), blocks: blocks)
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

    @inlinable
    public init(
        separator: Text,
        @TextBuilder blocks: () -> [Text]
    ) {
        let blocks = blocks()
        switch blocks.count {
        case 0:
            self = Text(verbatim: "")

        case 1:
            self = blocks[0]

        default:
            self = blocks.dropFirst().reduce(into: blocks[0]) { result, text in
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

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { Text("Flag") }

                let text = Text {
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
                }

                text

                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    text
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}
