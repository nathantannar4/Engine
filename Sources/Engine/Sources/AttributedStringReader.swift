//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that resolves `Text` with the current environment
@frozen
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AttributedStringReader<Content: View>: View {

    @usableFromInline
    var text: Text?

    @usableFromInline
    var content: (AttributedString?) -> Content

    @Environment(\.self) var environment

    @inlinable
    public init(
        _ text: Text,
        @ViewBuilder content: @escaping (AttributedString) -> Content
    ) {
        self.text = text
        self.content = { content($0!) }
    }

    @inlinable
    public init(
        _ text: Text?,
        @ViewBuilder content: @escaping (AttributedString?) -> Content
    ) {
        self.text = text
        self.content = content
    }

    @inlinable
    public init(
        _ text: LocalizedStringKey,
        @ViewBuilder content: @escaping (AttributedString) -> Content
    ) {
        self.init(Text(text), content: content)
    }

    public var body: some View {
        content(text?.resolveAttributed(in: environment))
    }
}


// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AttributedStringReader_Previews: PreviewProvider {
    struct TextPreview: View {
        var text: Text?

        var body: some View {
            HStack {
                text

                AttributedStringReader(text) { text in
                    Text(text)
                }
            }
        }
    }
    static var previews: some View {
        VStack {
            TextPreview(
                text: Text("Hello, World")
                    .font(.title3.weight(.bold))
            )

            if #available(iOS 16.1, macOS 13.0, tvOS 16.1, watchOS 9.1, *) {
                TextPreview(
                    text: Text("Hello, World")
                        .fontDesign(.serif)
                )
            }

            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                TextPreview(
                    text: Text("Hello, World")
                        .monospaced()
                )

                TextPreview(
                    text: Text("Hello, World 123")
                        .monospacedDigit()
                )
            }

            TextPreview(
                text: Text("Hello, World")
                    .fontWeight(.bold)
                    .strikethrough()
            )

            TextPreview(
                text: Text(verbatim: "Hello, World")
                    .font(.subheadline)
                    .foregroundColor(.red)
            )

            TextPreview(
                text: Text {
                    Text(verbatim: "Hello")
                        .font(.body.weight(.bold))
                        .foregroundColor(.red)

                    Text("World")
                        .underline()
                }
            )
        }
    }
}
