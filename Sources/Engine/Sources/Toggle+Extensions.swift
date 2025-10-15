//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Toggle {

    public init(
        _ configuration: ToggleStyleConfiguration,
        @ViewBuilder label: (ToggleStyleConfiguration.Label) -> Label
    ) {
        self.init(isOn: configuration.$isOn) {
            label(configuration.label)
        }
    }
}

// MARK: - Previews

struct Toggle_Previews: PreviewProvider {

    struct PreviewToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .border(Color.accentColor)
        }
    }

    struct PreviewButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .border(Color.accentColor)
        }
    }

    struct PreviewPrimitiveButtonStyle: PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(configuration) { label in
                label
                    .padding(8)
                    .border(Color.accentColor)
            }
        }
    }

    struct Preview: View {
        @State var flag = true

        var body: some View {
            VStack {
                let toggle = Toggle(isOn: $flag) {
                    Text(flag.description)
                }

                toggle
                    .toggleStyle(PreviewToggleStyle())

                #if !os(tvOS)
                if #available(iOS 15.0, macOS 12.0, watchOS 9.0, *) {
                    toggle
                        .toggleStyle(.button)
                        .buttonStyle(PreviewButtonStyle())

                    toggle
                        .toggleStyle(.button)
                        .buttonStyle(PreviewPrimitiveButtonStyle())
                        .buttonStyle(.plain)
                }
                #endif
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}
