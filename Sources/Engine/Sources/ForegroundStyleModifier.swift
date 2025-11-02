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
