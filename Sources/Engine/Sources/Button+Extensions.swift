//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Button {

    public init(
        _ configuration: PrimitiveButtonStyleConfiguration,
        @ViewBuilder label: (PrimitiveButtonStyleConfiguration.Label) -> Label
    ) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            self.init(role: configuration.role, action: configuration.trigger) {
                label(configuration.label)
            }
        } else {
            self.init(action: configuration.trigger) {
                label(configuration.label)
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension ButtonRole {
    
    /// A custom role identified by a `UInt8`.
    ///
    /// 0: .destructive
    /// 1: .cancel
    /// 2: .confirm
    /// 3: .close
    public init(rawValue: UInt8) {
        precondition(MemoryLayout<ButtonRole>.size == MemoryLayout<UInt8>.size)
        self = unsafeBitCast(rawValue, to: ButtonRole.self)
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
struct Button_Previews: PreviewProvider {

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
                let button = Button {
                    flag.toggle()
                } label: {
                    Text(flag.description)
                }

                button
                    .buttonStyle(PreviewButtonStyle())

                button
                    .buttonStyle(PreviewPrimitiveButtonStyle())
                    .buttonStyle(.plain)
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}
