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
                ZStack(alignment: .bottomTrailing) {
                    let label = Text(label)
                        .foregroundColor(color)
                        .background(color.opacity(0.3))
                        .alignmentGuide(VerticalAlignment.bottom) { d in
                            d[.bottom] - d.height / 2
                        }
                        .padding(2)

                    Rectangle()
                        .strokeBorder(color, lineWidth: 2)
                        .invertedMask(alignment: .bottomTrailing) {
                            label
                                .overlay(Rectangle())
                        }

                    label
                        .border(color, width: 2)
                }
            )
            #endif
    }
}

extension View {

    /// A view that flashes a debug overlay to indicate when a view update occurred
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
        VStack {
            Text("Hello, World")
                .padding()
                .withDebugOverlay(label: "Text", color: .red)
                .padding()
                .withDebugOverlay(label: "Padding", color: .blue)
        }
    }
}
