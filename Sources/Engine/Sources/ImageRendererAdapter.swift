//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// The resulting image from ``ImageRendererAdapter``
public struct ImageRenderedView: View {

    public var cgImage: CGImage
    public var scale: CGFloat

    public var image: Image {
        Image(decorative: cgImage, scale: scale)
    }

    public var size: CGSize {
        CGSize(width: CGFloat(cgImage.width) / scale, height: CGFloat(cgImage.height) / scale)
    }

    public var body: some View {
        image
    }
}

/// A view that transforms the source view into an ``Image`` with ``ImageRenderer``
///
/// The image is rendered with the current environments display scale, and
/// color scheme. Any other environment values are not propogated.
///
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct ImageRendererAdapter<
    Source: View,
    Content: View
>: View {

    var proposedSize: ProposedViewSize
    var source: Source
    var content: (ImageRenderedView?) -> Content

    @UpdatePhase var phase
    @Environment(\.displayScale) var displayScale
    @Environment(\.colorScheme) var colorScheme

    public init(
        proposedSize: ProposedViewSize = .unspecified,
        @ViewBuilder source: () -> Source,
        @ViewBuilder content: @escaping (ImageRenderedView?) -> Content
    ) {
        self.proposedSize = proposedSize
        self.source = source()
        self.content = content
    }

    public var body: some View {
        ImageRendererAdapterBody(
            configuration: ImageRendererConfiguration(
                phase: phase,
                scale: displayScale,
                proposedSize: proposedSize,
                colorScheme: colorScheme
            ),
            source: source,
            content: content
        )
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct ImageRendererConfiguration: Equatable {
    var phase: UpdatePhase.Value
    var scale: CGFloat
    var proposedSize: ProposedViewSize
    var colorScheme: ColorScheme
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct ImageRendererAdapterBody<
    Source: View,
    Content: View
>: View {

    var configuration: ImageRendererConfiguration
    var source: Source
    var content: (ImageRenderedView?) -> Content

    @StateObject var renderer: ImageRenderer<ImageRendererSourceView<Source>>

    public init(
        configuration: ImageRendererConfiguration,
        source: Source,
        content: @escaping (ImageRenderedView?) -> Content
    ) {
        self.configuration = configuration
        self.source = source
        self.content = content
        self._renderer = StateObject(wrappedValue: {
            let renderer = ImageRenderer(
                content: ImageRendererSourceView(
                    content: source,
                    colorScheme: configuration.colorScheme
                )
            )
            renderer.scale = configuration.scale
            renderer.proposedSize = configuration.proposedSize
            return renderer
        }())
    }

    var body: some View {
        content(renderer.image)
            .task(id: configuration) { @MainActor in
                guard configuration.phase.updates > 1 else { return }
                renderer.scale = configuration.scale
                renderer.proposedSize = configuration.proposedSize
                renderer.content = ImageRendererSourceView(
                    content: source,
                    colorScheme: configuration.colorScheme
                )
            }
    }
}

private struct ImageRendererSourceView<Content: View>: View {

    var content: Content
    var colorScheme: ColorScheme

    var body: some View {
        content
            .environment(\.colorScheme, colorScheme)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ImageRenderer {

    @MainActor
    var image: ImageRenderedView? {
        if let cgImage {
            return ImageRenderedView(cgImage: cgImage, scale: scale)
        }
        return nil
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct ImageRendererAdapter_Previews: PreviewProvider {
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

                ImageRendererAdapter {
                    Text("Hello, World")
                        .foregroundColor(flag ? Color.green : Color.red)
                } content: { image in
                    image
                }

                ImageRendererAdapter {
                    Text("Hello, World")
                } content: { image in
                    image?
                        .background(.background)
                }
                .environment(\.colorScheme, flag ? .dark : .light)

                // If you want to propogate the environment
                EnvironmentValueReader(\.self) { environment in
                    ImageRendererAdapter {
                        Text("Hello, World")
                            .foregroundColor(flag ? Color.green : Color.red)
                            .environment(\.self, environment)
                    } content: { image in
                        image
                    }
                }
                .font(.title)

                ImageRendererAdapter {
                    Text("Hello, World")
                        .foregroundColor(flag ? Color.green : Color.red)
                } content: { _ in
                    EmptyView()
                }
                .border(Color.red)

                HStack {
                    ImageRendererAdapter {
                        Text("Hello, World")
                            .foregroundColor(flag ? Color.green : Color.red)
                    } content: { image in
                        image
                        image
                    }
                }

                ImageRendererAdapter {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                } content: { image in
                    ZStack {
                        image

                        if let size = image?.size {
                            Text(size.debugDescription)
                        }
                    }
                }

                ImageRendererAdapter(proposedSize: ProposedViewSize(width: 100, height: 100)) {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                } content: { image in
                    ZStack {
                        image

                        if let size = image?.size {
                            Text(size.debugDescription)
                        }
                    }
                }
            }
        }
    }
}
