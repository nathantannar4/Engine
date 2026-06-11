//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that transforms the attachment view into a ``Text`` with ``ImageRenderer``
///
/// The proposed height of the attachment is determined by the environments font, with a
/// baseline offset applied to center the attachment in the line.
///
/// The attachment is rendered with the current environments display scale, and
/// will update when the attachment changes
///
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@frozen
public struct TextAttachmentAdapter<
    Attachment: View,
    Content: View
>: View {

    public var attachment: Attachment
    public var content: (Text) -> Content

    @Environment(\.self) var environment

    public init(
        @ViewBuilder content: @escaping (Text) -> Content,
        @ViewBuilder attachment: () -> Attachment
    ) {
        self.attachment = attachment()
        self.content = content
    }

    public var body: some View {
        let font = environment.font?.toPlatformValue(in: environment)
        ImageRendererAdapter(
            proposedSize: ProposedViewSize(
                width: nil,
                height: font?.capHeight
            )
        ) {
            attachment
                .font(environment.font)
        } content: { view in
            let attachment: Text? = {
                guard let view else { return nil }
                if let font {
                    let baselineOffset = ((font.lineHeight - view.size.height) / 2 + font.descender).rounded(scale: view.scale)
                    return Text(view.image).baselineOffset(baselineOffset)
                }
                return Text(view.image)
            }()
            content(attachment ?? Text(""))
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct TextAttachmentAdapter_Previews: PreviewProvider {
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

                TextAttachmentAdapter { attachment in
                    Text("\(attachment) Hello, World")
                } attachment: {
                    Text("•")
                }
                .fontWeight(flag ? .thin : .heavy)
                .font(.title)

                TextAttachmentAdapter { attachment in
                    Text("\(attachment) Hello, World")
                } attachment: {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                }
                .font(.body)

                TextAttachmentAdapter { attachment in
                    Text("\(attachment) Hello, World")
                } attachment: {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                .font(.body)

                TextAttachmentAdapter { attachment in
                    Text("\(attachment) Hello, World")
                } attachment: {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                        .frame(width: 24, height: 24)
                }
                .font(.body)

                // Attachment baseline not set if no font
                TextAttachmentAdapter { attachment in
                    Text("\(attachment) Hello, World")
                } attachment: {
                    Circle()
                        .fill(flag ? Color.green : Color.red)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}
