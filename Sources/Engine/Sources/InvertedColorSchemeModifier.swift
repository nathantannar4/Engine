//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct InvertedColorSchemeModifier: ViewModifier {

    var isEnabled: Bool

    @Environment(\.colorScheme) var colorScheme

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, colorScheme.inverted, isEnabled: isEnabled)
    }
}

extension View {

    public func invertColorScheme(isEnabled: Bool = true) -> some View {
        modifier(InvertedColorSchemeModifier(isEnabled: isEnabled))
    }
}

extension ColorScheme {

    var inverted: ColorScheme {
        switch self {
        case .light:
            return .dark
        case .dark:
            return .light
        default:
            return self
        }
    }
}

// MARK: - Previews

struct InvertedColorSchemeModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isEnabled = true

        var body: some View {
            VStack {
                Text("Hello, World")
                    .invertColorScheme(isEnabled: isEnabled)
                    .padding()
                    .background(Color.primary)

                Text("Hello, World")
                    .invertColorScheme(isEnabled: isEnabled)
                    .padding()
                    .background(Color.primary)
                    .invertColorScheme(isEnabled: isEnabled)

                Toggle(isOn: $isEnabled) {
                    Text("isEnabled")
                }
            }
        }
    }
}
