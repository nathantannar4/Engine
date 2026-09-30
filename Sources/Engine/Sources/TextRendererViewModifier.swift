//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A modifier that replaces the default text renderer with `Renderer`.
///
/// On iOS 18 and later this applies `textRenderer(_:)`. On earlier versions the
/// renderer is applied through SwiftUI's private implementation when available,
/// otherwise the content is left unmodified.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@frozen
public struct TextRendererViewModifier<
    Renderer: TextRenderer
>: VersionedViewModifier {

    @usableFromInline
    var renderer: Renderer

    /// Creates a modifier that renders text with `renderer`.
    @inlinable
    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    public func v6Body(content: Content) -> some View {
        content
            .textRenderer(renderer)
    }

    private enum IsTextRendererAvailable: StaticCondition {
        static var value: Bool {
            MemoryLayout<TextRendererViewModifier<Renderer>>.size == MemoryLayout<_TextRendererViewModifier<Renderer>>.size
        }
    }

    public func v5Body(content: Content) -> some View {
        StaticConditionalContent(IsTextRendererAvailable.self) {
            content
                .modifier(unsafeBitCast(self, to: _TextRendererViewModifier<Renderer>.self))
        } otherwise: {
            content
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
struct TextRendererViewModifier_Previews: PreviewProvider {

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    struct HiddenSeparatorOnLineBreakTextRenderer: TextRenderer {

        struct SeparatorAttribute: TextAttribute { }

        func draw(layout: Text.Layout, in context: inout GraphicsContext) {
            for line in layout {
                var lineContext = context
                if line[line.startIndex][SeparatorAttribute.self] != nil {
                    let leadingOffset = line[line.startIndex].typographicBounds.width
                    lineContext.translateBy(x: -leadingOffset, y: 0)
                }
                let lastIndex = line.index(before: line.endIndex)
                for index in line.indices {
                    let run = line[index]
                    let isSeparator = run[SeparatorAttribute.self] != nil
                    if isSeparator, index == line.startIndex || index == lastIndex {
                        continue
                    }
                    lineContext.draw(run)
                }
            }
        }
    }

    static var previews: some View {
        VStack(alignment: .leading, spacing: 24) {
            let separator = Text.dotSeparator
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    separator: separator
                ) {
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                }

                Text(
                    separator: separator.customAttribute(HiddenSeparatorOnLineBreakTextRenderer.SeparatorAttribute())
                ) {
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                }
                .modifier(TextRendererViewModifier(renderer: HiddenSeparatorOnLineBreakTextRenderer()))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(
                    separator: separator
                ) {
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                }

                Text(
                    separator: separator.customAttribute(HiddenSeparatorOnLineBreakTextRenderer.SeparatorAttribute())
                ) {
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                    Text("Lorem ipsum")
                }
                .modifier(TextRendererViewModifier(renderer: HiddenSeparatorOnLineBreakTextRenderer()))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(
                    separator: separator
                ) {
                    Text("Lorem ipsum dolor sit amet consectetur amets")
                    Text("Lorem ipsum dolor sit amet consectetur amets")
                }

                Text(
                    separator: separator.customAttribute(HiddenSeparatorOnLineBreakTextRenderer.SeparatorAttribute())
                ) {
                    Text("Lorem ipsum dolor sit amet consectetur amets")
                    Text("Lorem ipsum dolor sit amet consectetur amets")
                }
                .modifier(TextRendererViewModifier(renderer: HiddenSeparatorOnLineBreakTextRenderer()))
            }
        }
        .padding()
    }
}
