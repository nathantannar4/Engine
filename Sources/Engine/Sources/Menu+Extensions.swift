//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension MenuStyleConfiguration {

    /// The action performed when the menu's label is tapped, if any.
    @available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
    public var primaryAction: (() -> Void)? {
        try? swift_getFieldValue("primaryAction", (() -> Void)?.self, self)
    }

    /// A view that represents the label of the menu.
    public var label: MenuStyle.Configuration.Label {
        let label = unsafeBitCast(Void(), to: MenuStyle.Configuration.Label.self)
        return label
    }

    /// A view that represents the content of the menu.
    public var content: MenuStyle.Configuration.Content {
        let content = unsafeBitCast(Void(), to: MenuStyle.Configuration.Content.self)
        return content
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension Menu {

    /// Creates a menu with an optional primary action.
    ///
    /// When `primaryAction` is `nil`, this is equivalent to a menu without a
    /// primary action, allowing the primary action to be toggled dynamically.
    public init(
        primaryAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        if let primaryAction {
            self.init(content: content, label: label, primaryAction: primaryAction)
        } else {
            self.init(content: content, label: label)
        }
    }

    /// Creates a menu from a style configuration with a custom label.
    ///
    /// Use this within a `MenuStyle` to restyle the label while preserving
    /// the configuration's content and primary action.
    ///
    ///     struct BorderedMenuStyle: MenuStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             Menu(configuration) { label in
    ///                 label
    ///                     .padding(8)
    ///                     .border(Color.accentColor)
    ///             }
    ///         }
    ///     }
    ///
    public init(
        _ configuration: MenuStyleConfiguration,
        @ViewBuilder label: (MenuStyleConfiguration.Label) -> Label
    ) where Content == MenuStyleConfiguration.Content {
        self.init(
            primaryAction: configuration.primaryAction,
            content: { configuration.content },
            label: {
                label(configuration.label)
            }
        )
    }
}

// MARK: - Previews

#if !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
struct Menu_Previews: PreviewProvider {

    struct PreviewMenuStyle: MenuStyle {
        func makeBody(configuration: Configuration) -> some View {
            Menu(configuration) { label in
                label
                    .padding(8)
                    .border(Color.accentColor)
            }
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
            Button(role: configuration.role) {
                configuration.trigger()
            } label: {
                configuration.label
                    .padding(8)
                    .border(Color.accentColor)
            }
        }
    }

    struct Preview: View {
        @State var isButton = true

        var body: some View {
            VStack {
                let menu = Menu(primaryAction: isButton ? { isButton.toggle() } : nil) {
                    if !isButton {
                        Button {
                            isButton = true
                        } label: {
                            Text(verbatim: "Enable")
                        }

                    }
                } label: {
                    Text(verbatim: isButton ? "Button" : "Menu")
                }

                menu
                    .menuStyle(PreviewMenuStyle())

                if #available(iOS 16.0, macOS 13.0, tvOS 17.0, *){
                    menu
                        .menuStyle(.button)
                        .buttonStyle(PreviewButtonStyle())

                    // PrimitiveButtonStyle's don't work with `.menuStyle(.button)`
                    menu
                        .menuStyle(.button)
                        .buttonStyle(PreviewPrimitiveButtonStyle())
                }
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
