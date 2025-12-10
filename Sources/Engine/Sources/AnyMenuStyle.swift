//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 17.0, *)
@available(watchOS, unavailable)
public struct AnyMenuStyle: MenuStyle {

    var style: any MenuStyle

    public init<S: MenuStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: MenuStyle>(_ style: S) -> some View {
            AnyView(
                AnyMenuStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 17.0, *)
@available(watchOS, unavailable)
private struct AnyMenuStyleBody<S: MenuStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
struct AnyMenuStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Menu {
                    Button("Action") {
                        withAnimation {
                            flag.toggle()
                        }
                    }
                } label: {
                    Text("Label")
                }
                .menuStyle(flag ? AnyMenuStyle(.automatic) : AnyMenuStyle(PreviewMenuStyle()))
            }
        }
    }

    struct PreviewMenuStyle: MenuStyle {
        func makeBody(configuration: Configuration) -> some View {
            Menu(configuration) { label in
                label
                    .padding(8)
                    .border(Color.blue)
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
