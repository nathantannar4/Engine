//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol TextReaderRenderer: DynamicProperty {

    associatedtype Body: View
    @ViewBuilder @MainActor @preconcurrency func makeBody(text: String) -> Body
}

/// A view that resolves `Text` with the current environment
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TextReader<
    Renderer: TextReaderRenderer
>: View {

    @usableFromInline
    var text: Text

    @usableFromInline
    var renderer: Renderer

    @inlinable
    public init(
        _ text: Text,
        renderer: Renderer
    ) {
        self.text = text
        self.renderer = renderer
    }

    @inlinable
    public init(
        _ text: LocalizedStringKey,
        renderer: Renderer
    ) {
        self.init(Text(text), renderer: renderer)
    }

    @inlinable
    public init<Content: View>(
        _ text: Text,
        @ViewBuilder content: @escaping (String) -> Content
    ) where Renderer == TextReaderDefaultRenderer<Content> {
        self.init(text, renderer: TextReaderDefaultRenderer(content: content))
    }

    @inlinable
    public init<Content: View>(
        _ text: LocalizedStringKey,
        @ViewBuilder content: @escaping (String) -> Content
    ) where Renderer == TextReaderDefaultRenderer<Content> {
        self.init(Text(text), content: content)
    }

    public var body: some View {
        TextReaderBody(
            text: text,
            renderer: renderer
        )
    }
}

@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TextReaderDefaultRenderer<
    Content: View
>: TextReaderRenderer {

    public var content: (String) -> Content

    public init(
        content: @escaping (String) -> Content
    ) {
        self.content = content
    }

    public func makeBody(text: String) -> some View {
        content(text)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct TextReaderBody<
    Renderer: TextReaderRenderer
>: View {

    var text: Text
    var renderer: Renderer

    @Environment(\.self) var environment

    var body: some View {
        let text = text.resolve(in: environment)
        renderer.makeBody(text: text)
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
            }
        }
    }
}
