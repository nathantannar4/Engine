//
//  VersionedViewExample.swift
//  Example
//
//  Created by Nathan Tannar on 2022-11-12.
//

import SwiftUI
import Engine

struct VersionedViewExamples: View {
    var body: some View {
        VersionText()

        GradientRectangle(color: .red)
            .frame(height: 32)

        Button {

        } label: {
            Text("Underline if #available")
        }
        .buttonStyle(UnderlineButtonStyle())
    }
}

struct VersionText: VersionedView {
    var v4Body: some View {
        Text("iOS 16 / macOS 13")
    }

    var v3Body: some View {
        Text("iOS 15 / macOS 12")
    }

    var v2Body: some View {
        Text("iOS 14 / macOS 11")
    }

    var v1Body: some View {
        Text("iOS 13 / macOS 10.15")
    }
}

struct GradientRectangle: VersionedView {
    var color: Color

    @available(iOS 16.0, macOS 13.0, *)
    var v4Body: some View {
        Rectangle()
            .fill(color.gradient)
    }

    var v1Body: some View {
        LinearGradient(
            stops: [
                .init(color: color.opacity(0.5), location: 0),
                .init(color: color, location: 0.25)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct UnderlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(UnderlineIfAvailableModifier())
    }
}

struct UnderlineIfAvailableModifier: VersionedViewModifier {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func v4Body(content: Content) -> some View {
        content.underline()
    }
}

struct VersionedViewExamples_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VersionedViewExamples()
        }
    }
}
