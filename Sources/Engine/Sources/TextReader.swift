//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that resolves `Text` with the current environment
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TextReader<Content: View>: View {

    @usableFromInline
    var text: Text?

    @usableFromInline
    var content: (String?) -> Content

    @inlinable
    public init(
        _ text: Text,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self.text = text
        self.content = { content($0!) }
    }

    @inlinable
    public init(
        _ text: Text?,
        @ViewBuilder content: @escaping (String?) -> Content
    ) {
        self.text = text
        self.content = content
    }

    @inlinable
    public init(
        _ text: LocalizedStringKey,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self.init(Text(text), content: content)
    }

    public var body: some View {
        TextReaderBody(text: text, content: content)
            .equatable()
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct TextReaderBody<Content: View>: View, Equatable {

    var text: Text?
    var content: (String?) -> Content

    var body: some View {
        TextReaderResolvedBody(text: text, content: content)
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.text == rhs.text
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct TextReaderResolvedBody<Content: View>: View {

    var text: Text?
    var content: (String?) -> Content

    @Environment(\.self) var environment

    var body: some View {
        content(text?.resolve(in: environment))
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct TextReader_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { EmptyView() }
                    .labelsHidden()

                TextReader(Text(verbatim: "Hello, World")) { text in
                    Text(verbatim: text)
                }

                TextReader("Hello, World") { text in
                    Text(verbatim: text)
                }
                .textCase(flag ? .lowercase : .uppercase)

                // Equatable thus changing the flag won't re-render
                TextReader("Hello, World") { text in
                    Text(verbatim: flag ? text.uppercased() : text.lowercased())
                }

                // Also won't re-render
                TextReader("Hello, World") { text in
                    ChildView(flag: flag, text: text)
                }
            }
        }

        struct ChildView: View {
            var flag: Bool
            var text: String

            var body: some View {
                Text(verbatim: flag ? text.uppercased() : text.lowercased())
            }
        }
    }
}
