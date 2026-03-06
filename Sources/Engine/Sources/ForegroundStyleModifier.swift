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

extension View {

    @_disfavoredOverload
    @available(iOS, introduced: 13.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    public func foregroundColor(
        _ color: Color?,
        isEnabled: Bool
    ) -> some View {
        modifier(ForegroundColorModifier(color: color, isEnabled: isEnabled))
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Text {

    /// Sets a view's foreground elements to use a given style when non-nil.
    @_disfavoredOverload
    @inlinable
    public func foregroundStyle<S: ShapeStyle>(
        _ style: S?
    ) -> Text {
        if let style {
            return foregroundStyle(style)
        }
        return self
    }
}

extension Text {

    @_disfavoredOverload
    @available(iOS, introduced: 13.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, renamed: "foregroundStyle(_:)")
    public func foregroundColor(
        _ color: Color?,
        isEnabled: Bool
    ) -> Text {
        if isEnabled {
            return foregroundColor(color)
        }
        return self
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

/// A modifier that sets a view's foreground elements to use a given style when non-nil.
@frozen
public struct ForegroundColorModifier: ViewModifier {

    public var color: Color?
    public var isEnabled: Bool

    @Environment(\.foregroundColor) private var foregroundColor

    @inlinable
    init(
        color: Color? = nil,
        isEnabled: Bool
    ) {
        self.color = color
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? color : foregroundColor)
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
                    .foregroundColor(Optional<Color>.none, isEnabled: false)

                Text("Hello, World")
                    .padding(.horizontal)
                    .foregroundColor(Optional<Color>.none, isEnabled: false)

                Text("Hello, World")
                    .foregroundStyle(Optional<Color>.none)

                Text("Hello, World")
                    .foregroundStyle(Optional<Color>.some(.red))

                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                    Text(separator: .newline) {
                        Text("Hello, World")
                            .foregroundStyle(Optional<Color>.some(.red))
                    }
                }

                Rectangle()
                    .frame(height: 30)

                Rectangle()
                    .frame(height: 30)
                    .foregroundStyle(Optional<Color>.some(.red))
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
