//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// The empty shape
@frozen
public struct EmptyShape: Shape {

    @inlinable
    public init() { }

    public func path(in rect: CGRect) -> Path {
        guard rect != .zero else { return Path() }
        return Path(rect).scale(10).path(in: rect)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        return .zero
    }
}

// MARK: - Previews

struct EmptyShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EmptyShape()
                .fill(Color.red)
                .frame(width: 100, height: 100)

            Rectangle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .clipShape {
                    EmptyShape()
                }

            Rectangle()
                .fill(Color.red)
                .frame(width: 100, height: 100)
                .scaleEffect(2)
                .clipShape {
                    Rectangle()
                }

            Rectangle()
                .fill(Color.yellow)
                .frame(width: 100, height: 100)
                .scaleEffect(2)
                .clipShape {
                    EmptyShape()
                }
        }
    }
}
