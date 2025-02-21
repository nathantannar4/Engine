//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Text {

    @_disfavoredOverload
    public init<S: StringProtocol, Content: View>(
        attachment: Content,
        label: S
    ) {
        self.init(attachment: attachment, label: Text(label))
    }

    public init<Content: View>(
        attachment: Content,
        label: LocalizedStringKey
    ) {
        self.init(attachment: attachment, label: Text(label))
    }

    public init<Content: View>(
        attachment: Content,
        label: Text? = nil
    ) {
        let renderer = ImageRenderer(content: attachment)
        if let cgImage = renderer.cgImage {
            let image: Image = {
                if let label {
                    return Image(
                        cgImage,
                        scale: renderer.scale,
                        orientation: .up,
                        label: label
                    )
                } else {
                    return Image(
                        decorative: cgImage,
                        scale: renderer.scale,
                        orientation: .up
                    )
                }
            }()
            self.init(image)
        } else {
            self.init(verbatim: "")
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
            }
        }
    }
}
