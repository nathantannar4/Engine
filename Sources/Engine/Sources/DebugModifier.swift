//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier to help debugging
///
/// > Note: DEBUG builds only
@frozen
public struct DebugOverlayModifier: ViewModifier {

    var label: String
    var color: Color

    public init(label: String, color: Color) {
        self.label = label
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            #if DEBUG
            .overlay(
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        Rectangle()
                            .strokeBorder(color, lineWidth: 2)

                        Text(verbatim: "\(size.width.rounded(decimalPoints: 1)), \(size.height.rounded(decimalPoints: 1))")
                            .fixedSize()
                            .background(color.opacity(0.3))
                            .alignmentGuide(VerticalAlignment.center) { d in
                                d[VerticalAlignment.center] + (size.height + d.height) / 2
                            }
                            .alignmentGuide(HorizontalAlignment.center) { d in
                                d[HorizontalAlignment.center] + (size.width - d.width) / 2
                            }
                            .frame(width: size.width, height: size.height, alignment: .center)

                        Text(label)
                            .background(color.opacity(0.3))
                            .fixedSize()
                            .alignmentGuide(VerticalAlignment.center) { d in
                                d[VerticalAlignment.center] - (size.height + d.height) / 2
                            }
                            .alignmentGuide(HorizontalAlignment.center) { d in
                                d[HorizontalAlignment.center] - (size.width - d.width) / 2
                            }
                            .frame(width: size.width, height: size.height, alignment: .center)
                    }
                }
            )
            #endif
    }
}

extension View {

    /// A modifier that draws a border around the frame with a label
    ///
    /// > Note: DEBUG builds only
    public func withDebugOverlay(label: String, color: Color) -> some View {
        #if DEBUG
        modifier(DebugOverlayModifier(label: label, color: color))
        #else
        self
        #endif
    }
}

// MARK: - Previews

struct DebugOverlayModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 48) {
            Text("Hello, World")
                .padding(32)
                .withDebugOverlay(label: "Text", color: .red)
                .padding(32)
                .withDebugOverlay(label: "Padding", color: .blue)

            Text("Text")
                .withDebugOverlay(label: "Label", color: .red)
        }
    }
}
