//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Sets a view's foreground elements to use a given style when non-nil.
    @_disfavoredOverload
    @inlinable
    public func foregroundStyle<S: ShapeStyle>(
        _ style: S?
    ) -> some View {
        modifier(ForegroundStyleModifier(style: style))
    }
}

/// A modifier that sets a view's foreground elements to use a given style when non-nil.
@frozen
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ForegroundStyleModifier<
    S: ShapeStyle
>: ViewModifier {

    public var style: S?

    @Environment(\.foregroundStyle) private var foregroundStyle

    @inlinable
    init(style: S? = nil) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .foregroundStyle(style.map { AnyShapeStyle($0) } ?? foregroundStyle)
    }
}

// MARK: - ForegroundStyleModifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ForegroundStyleModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let labels = VStack {
                Text("Hello, World")

                Text("Hello, World")
                    .foregroundStyle(Optional<Color>.none)

                Text("Hello, World")
                    .foregroundColor(.red)

                Text("Hello, World")
                    .foregroundStyle(.red)

                Rectangle()
                    .frame(height: 30)

                Rectangle()
                    .frame(height: 30)
                    .foregroundStyle(.red)
            }
            .font(.title)

            labels
                .foregroundStyle(Color.green)

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                labels
                    .foregroundStyle(Color.green.gradient)
            }
        }
    }
}
