//
//  LayoutThatFitsExample.swift
//  Example
//
//  Created by Nathan Tannar on 2022-11-12.
//

import SwiftUI
import Engine

@available(iOS 16.0, macOS 13.0, *)
struct LayoutThatFitsExample: View {

    @State var maxWidth: CGFloat = 350

    var body: some View {
        VStack {
            Slider(value: $maxWidth, in: 0...350) {
                Text("LayoutThatFits")
            }

            AdaptiveStack(spacing: 0) {
                Group {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
                .background(Color.gray)
            }
            .frame(width: maxWidth)
            .border(Color.red, width: 2)
        }
    }
}

/// A stack that adjusts from horizontal to vertical if there is not enough
/// horizontal space.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AdaptiveStack<Content: View>: View {

    var alignment: Alignment
    var spacing: CGFloat?
    var content: Content

    init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LayoutThatFits(
            in: .horizontal,
            _HStackLayout(alignment: alignment.vertical, spacing: spacing),
            _VStackLayout(alignment: alignment.horizontal, spacing: spacing)
        ) {
            content
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct LayoutThatFitsExample_Previews: PreviewProvider {
    static var previews: some View {
        LayoutThatFitsExample()
    }
}
