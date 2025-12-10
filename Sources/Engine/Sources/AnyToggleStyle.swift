//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct AnyToggleStyle: ToggleStyle {

    var style: any ToggleStyle

    public init<S: ToggleStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: ToggleStyle>(_ style: S) -> some View {
            AnyView(
                AnyToggleStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

private struct AnyToggleStyleBody<S: ToggleStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

struct AnyToggleStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Toggle(isOn: $flag) {
                    Text("Label")
                }
                .toggleStyle(flag ? AnyToggleStyle(.automatic) : AnyToggleStyle(PreviewToggleStyle()))
            }
        }
    }

    struct PreviewToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Toggle(configuration) { label in
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
