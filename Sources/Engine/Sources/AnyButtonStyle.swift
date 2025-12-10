//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct AnyButtonStyle: PrimitiveButtonStyle {

    var style: any PrimitiveButtonStyle

    public init<S: ButtonStyle>(_ style: S) {
        self.style = _PrimitiveButtonStyle(style)
    }

    public init<S: PrimitiveButtonStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: PrimitiveButtonStyle>(_ style: S) -> some View {
            AnyView(
                AnyPrimitiveButtonStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

public struct _PrimitiveButtonStyle<S: ButtonStyle>: PrimitiveButtonStyle {

    var style: S

    public init(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(style)
    }
}

private struct AnyPrimitiveButtonStyleBody<S: PrimitiveButtonStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

struct AnyButtonStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                HStack {
                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        PreviewPrimitiveButtonStyleA()
                    )
                    .buttonStyle(
                        PreviewButtonStyleA()
                    )

                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        PreviewPrimitiveButtonStyleA()
                    )
                    .buttonStyle(
                        PreviewPrimitiveButtonStyleB()
                    )
                    .buttonStyle(
                        PreviewButtonStyleB()
                    )
                }

                HStack {
                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        AnyButtonStyle(PreviewPrimitiveButtonStyleA())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewButtonStyleA())
                    )

                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        AnyButtonStyle(PreviewPrimitiveButtonStyleA())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewPrimitiveButtonStyleB())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewButtonStyleB())
                    )
                }

                VStack {
                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        flag ? AnyButtonStyle(PreviewButtonStyleB()) : AnyButtonStyle(PreviewPrimitiveButtonStyleA())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewButtonStyleA())
                    )

                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        flag ? AnyButtonStyle(PreviewButtonStyleA()) : AnyButtonStyle(PreviewPrimitiveButtonStyleA())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewPrimitiveButtonStyleB())
                    )
                    .buttonStyle(
                        AnyButtonStyle(PreviewButtonStyleB())
                    )

                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        Text("Label")
                    }
                    .buttonStyle(
                        flag ? AnyButtonStyle(PreviewPrimitiveButtonStyleA()) : AnyButtonStyle(PreviewPrimitiveButtonStyleB())
                    )
                }
            }
        }
    }

    struct PreviewButtonStyleA: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .border(Color.red)
        }
    }

    struct PreviewButtonStyleB: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .border(Color.blue)
        }
    }

    struct PreviewPrimitiveButtonStyleA: PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(configuration) { label in
                label
                    .padding(8)
                    .border(Color.green)
            }
        }
    }

    struct PreviewPrimitiveButtonStyleB: PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(configuration) { label in
                label
                    .padding(8)
                    .border(Color.yellow)
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
