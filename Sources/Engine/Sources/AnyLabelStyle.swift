//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct AnyLabelStyle: LabelStyle {

    var style: any LabelStyle

    public init<S: LabelStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: LabelStyle>(_ style: S) -> some View {
            AnyView(
                AnyLabelStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct AnyLabelStyleBody<S: LabelStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct AnyLabelStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Label {
                    Button("Action") {
                        withAnimation {
                            flag.toggle()
                        }
                    }
                } icon: {
                    Text("Icon")
                }
                .labelStyle(flag ? AnyLabelStyle(.titleOnly) : AnyLabelStyle(.automatic))
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
