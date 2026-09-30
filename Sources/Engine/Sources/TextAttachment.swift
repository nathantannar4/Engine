//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Text {

    /// Creates a text containing a snapshot of `attachment` rendered as an image.
    ///
    /// - Parameters:
    ///   - attachment: The view to render into an image.
    ///   - environment: The environment to render the attachment in. When `nil`, the
    ///     attachment is rendered at the main screen's scale with the default environment.
    ///   - label: The accessibility label of the image. When `nil`, the image is decorative.
    @_disfavoredOverload
    public init<S: StringProtocol, Content: View>(
        attachment: Content,
        environment: EnvironmentValues? = nil,
        label: S?
    ) {
        self.init(
            attachment: attachment,
            environment: environment,
            label: Text(label)
        )
    }

    /// Creates a text containing a snapshot of `attachment` rendered as an image.
    ///
    /// - Parameters:
    ///   - attachment: The view to render into an image.
    ///   - environment: The environment to render the attachment in. When `nil`, the
    ///     attachment is rendered at the main screen's scale with the default environment.
    ///   - label: The localized accessibility label of the image.
    public init<Content: View>(
        attachment: Content,
        environment: EnvironmentValues? = nil,
        label: LocalizedStringKey
    ) {
        self.init(
            attachment: attachment,
            environment: environment,
            label: Text(label)
        )
    }

    /// Creates a text containing a snapshot of `attachment` rendered as an image.
    ///
    /// If the attachment fails to render, the text is the `label`, or empty when
    /// there is no label.
    ///
    /// - Parameters:
    ///   - attachment: The view to render into an image.
    ///   - environment: The environment to render the attachment in. When `nil`, the
    ///     attachment is rendered at the main screen's scale with the default environment.
    ///   - label: The accessibility label of the image. When `nil`, the image is decorative.
    public init<Content: View>(
        attachment: Content,
        environment: EnvironmentValues? = nil,
        label: Text? = nil
    ) {
        var cgImage: CGImage?
        var scale: CGFloat = 1
        if let environment {
            let renderer = ImageRenderer(
                content: attachment.environment(\.self, environment)
            )
            renderer.scale = environment.displayScale
            cgImage = renderer.cgImage
            scale = renderer.scale
        } else {
            let renderer = ImageRenderer(
                content: attachment
            )
            #if os(iOS) || os(tvOS)
            renderer.scale = UIScreen.main.scale
            #elseif canImport(AppKit)
            renderer.scale = NSScreen.main?.backingScaleFactor ?? 1
            #endif
            cgImage = renderer.cgImage
            scale = renderer.scale
        }
        if let cgImage {
            let image: Image = {
                if let label {
                    return Image(
                        cgImage,
                        scale: scale,
                        orientation: .up,
                        label: label
                    )
                } else {
                    return Image(
                        decorative: cgImage,
                        scale: scale,
                        orientation: .up
                    )
                }
            }()
            self.init(image)
        } else {
            self = label ?? Text(verbatim: "")
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct TextAttachment_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        var body: some View {
            VStack {
                Text(attachment: Circle())

                Text("Here is an embedded circle \(Text(attachment: Circle()))")

                Text("\(Text(attachment: Circle())) Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis.")
            }
            .padding()
        }
    }
}
