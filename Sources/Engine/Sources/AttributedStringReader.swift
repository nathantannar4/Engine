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
        var text: Text

        @Environment(\.self) var environment

        var body: some View {
            VStack(spacing: 4) {
                text

                AttributedStringReader(text) { attributedString in
                    Text(attributedString)
                }

                #if os(iOS) || os(macOS)
                let attributedText: NSAttributedString = text.resolveAttributed(in: environment)
                Label(attributedText: attributedText)

                AttributedStringReader(text) { attributedString in
                    #if os(iOS)
                    let attributedText = try? NSAttributedString(
                        attributedString.toUIKit(in: environment),
                        including: \.uiKit
                    )
                    #else
                    let attributedText = try? NSAttributedString(
                        attributedString.toAppKit(in: environment),
                        including: \.appKit
                    )
                    #endif
                    Label(attributedText: attributedText ?? NSAttributedString())
                }
                #endif
            }
            .frame(maxWidth: .infinity)
        }

        #if os(iOS)
        struct Label: UIViewRepresentable {
            var attributedText: NSAttributedString

            func makeUIView(context: Context) -> UILabel {
                let uiView = UILabel()
                uiView.setContentHuggingPriority(.required, for: .vertical)
                uiView.setContentHuggingPriority(.required, for: .horizontal)
                return uiView
            }

            func updateUIView(_ uiView: UILabel, context: Context) {
                uiView.attributedText = attributedText
            }
        }
        #elseif os(macOS)
        struct Label: NSViewRepresentable {
            var attributedText: NSAttributedString

            func makeNSView(context: Context) -> NSTextField {
                let nsView = NSTextField()
                nsView.setContentHuggingPriority(.required, for: .vertical)
                nsView.setContentHuggingPriority(.required, for: .horizontal)
                nsView.isEditable = false
                nsView.isSelectable = false
                nsView.isBezeled = false
                nsView.drawsBackground = false
                return nsView
            }

            func updateNSView(_ nsView: NSTextField, context: Context) {
                nsView.attributedStringValue = attributedText
            }
        }
        #endif
    }
    static var previews: some View {
        ScrollView {
            VStack {
                TextPreview(
                    text: Text(Date.now, format: .dateTime)
                )

                TextPreview(
                    text: Text(1_000_000, format: .number)
                )

                TextPreview(
                    text: Text(NSNumber(floatLiteral: 26.2), formatter: NumberFormatter())
                )

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

                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    TextPreview(
                        text: Text("Hello, World")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .strikethrough(pattern: .dash, color: .black)
                    )
                }

                TextPreview(
                    text: Text(verbatim: "Hello, World")
                        .font(.subheadline)
                        .foregroundColor(.red)
                )

                TextPreview(
                    text: Text("Hello, World")
                        .underline()
                )

                TextPreview(
                    text: Text("Hello, World")
                        .foregroundColor(.red)
                        .underline(color: .black)
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

                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                    TextPreview(
                        text: Text("Hello, World")
                            .textScale(.secondary)
                    )
                }

                VStack {
                    Text("Hello, World")

                    AttributedStringReader(Text("Hello, World")) { text in
                        Text(verbatim: String(text.characters))
                            .textCase(nil)
                    }
                }
                .textCase(.uppercase)

                TextPreview(
                    text: Text(Image(systemName: "trash"))
                )

                TextPreview(
                    text: Text("\(Image(systemName: "trash")) Delete")
                )
            }
        }
    }
}
