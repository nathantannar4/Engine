//
// Copyright (c) Nathan Tannar
//

import SwiftUI

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
    static var previews: some View {
        VStack {
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
