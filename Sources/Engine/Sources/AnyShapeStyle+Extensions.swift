//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @_disfavoredOverload
    @inlinable
    public func foregroundStyle<S: ShapeStyle>(
        _ style: S?
    ) -> some View {
        modifier(ForegroundStyleModifier(style: style))
    }
}

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AnyShapeStyle {

    public var color: Color? {
        func resolve(provider: Any) -> Color? {
            let className = String(describing: type(of: provider))
            if className.hasPrefix("ColorBox") {
                guard MemoryLayout<Color>.size == MemoryLayout<AnyObject>.size else {
                    return nil
                }
                let color = unsafeBitCast(provider as AnyObject, to: Color.self)
                return color
            } else if className.hasPrefix("GradientBox") {
                guard
                    let provider = Mirror(reflecting: provider).descendant("base", "color", "provider"),
                    let resolved = resolve(provider: provider)
                else {
                    return nil
                }
                return resolved
            } else {
                return nil
            }
        }

        guard 
            let box = Mirror(reflecting: self).descendant("storage", "box"),
            let resolved = resolve(provider: box)
        else {
            return nil
        }
        return resolved
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AnyShapeStyle_Previews: PreviewProvider {
    struct StyledText: View {
        var color: Color?

        var body: some View {
            Text("Hello, World")
                .foregroundStyle(color)
        }
    }
    static var previews: some View {
        VStack {
            VStack {
                StyledText(color: .red)

                StyledText(color: nil)
                    .foregroundStyle(.red)
            }

            HStack {
                Rectangle()
                    .fill(AnyShapeStyle(Color.red).color ?? .clear)

                Rectangle()
                    .fill(Color.red)
            }

            HStack {
                Rectangle()
                    .fill(AnyShapeStyle(Color.red.gradient).color ?? .clear)

                Rectangle()
                    .fill(Color.red.gradient)
            }
        }
    }
}
