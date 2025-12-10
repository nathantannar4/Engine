//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct AnyLabeledContentStyle: LabeledContentStyle {

    var style: any LabeledContentStyle

    public init<S: LabeledContentStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: LabeledContentStyle>(_ style: S) -> some View {
            AnyView(
                AnyLabeledContentStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct AnyLabeledContentStyleBody<S: LabeledContentStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AnyLabeledContentStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                LabeledContent {
                    Button("Content") {
                        withAnimation {
                            flag.toggle()
                        }
                    }
                } label: {
                    Text("Label")
                }
                .labeledContentStyle(flag ? AnyLabeledContentStyle(PreviewLabeledContentStyle()) : AnyLabeledContentStyle(.automatic))
            }
        }
    }

    struct PreviewLabeledContentStyle: LabeledContentStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                configuration.content
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
