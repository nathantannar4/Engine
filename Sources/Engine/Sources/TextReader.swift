//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A type that makes the body of a ``TextReader`` from the resolved string of a `Text`.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol TextReaderRenderer: DynamicProperty {

    /// The type of view representing the body.
    associatedtype Body: View
    /// Creates the view that represents the body, given the resolved string of the text.
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

    /// Creates a view that resolves `text` in the current environment and passes
    /// the resolved string to `renderer`.
    @inlinable
    public init(
        _ text: Text,
        renderer: Renderer
    ) {
        self.text = text
        self.renderer = renderer
    }

    /// Creates a view that resolves a localized string in the current environment and
    /// passes the resolved string to `renderer`.
    @inlinable
    public init(
        _ text: LocalizedStringKey,
        renderer: Renderer
    ) {
        self.init(Text(text), renderer: renderer)
    }

    /// Creates a view that resolves `text` in the current environment and passes
    /// the resolved string to `content`.
    @inlinable
    public init<Content: View>(
        _ text: Text,
        @ViewBuilder content: @escaping (String) -> Content
    ) where Renderer == TextReaderDefaultRenderer<Content> {
        self.init(text, renderer: TextReaderDefaultRenderer(content: content))
    }

    /// Creates a view that resolves a localized string in the current environment and
    /// passes the resolved string to `content`.
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

/// A ``TextReaderRenderer`` that makes its body from a closure.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TextReaderDefaultRenderer<
    Content: View
>: TextReaderRenderer {

    /// The closure that makes the body from the resolved string.
    public var content: (String) -> Content

    /// Creates a renderer that makes its body with `content`.
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
