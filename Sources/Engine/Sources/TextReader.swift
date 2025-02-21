//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that resolves `Text` with the current environment
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TextReader<Content: View>: View {

    @usableFromInline
    var text: Text

    @usableFromInline
    var content: (String) -> Content

    @Environment(\.self) var environment

    @inlinable
    public init(_ text: Text, @ViewBuilder content: @escaping (String) -> Content) {
        self.text = text
        self.content = content
    }

    @inlinable
    public init(_ text: LocalizedStringKey, @ViewBuilder content: @escaping (String) -> Content) {
        self.init(Text(text), content: content)
    }

    public var body: some View {
        content(text.resolve(in: environment))
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct TextReader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextReader(Text(verbatim: "Hello, World")) { text in
                Text(verbatim: text)
            }

            TextReader(LocalizedStringKey("Hello, World")) { text in
                Text(verbatim: text)
            }
        }
    }
}
