//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct InsetShape<S: Shape>: Shape, InsettableShape {

    public var shape: S
    public var insets: EdgeInsets

    @inlinable
    public init(shape: S, insets: EdgeInsets) {
        self.insets = insets
        self.shape = shape
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let insetRect = CGRect(
            x: rect.minX + insets.leading,
            y: rect.minY + insets.top,
            width: max(0, rect.width - insets.leading - insets.trailing),
            height: max(0, rect.height - insets.top - insets.bottom)
        )
        return shape.path(in: insetRect)
    }

    public nonisolated func inset(by amount: CGFloat) -> InsetShape<S> {
        var insets = insets
        insets.top += amount
        insets.bottom += amount
        insets.leading += amount
        insets.trailing += amount
        return InsetShape(shape: shape, insets: insets)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var role: ShapeRole {
        S.role
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior {
        shape.layoutDirectionBehavior
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        shape.sizeThatFits(proposal)
    }
}

extension Shape {

    @inlinable
    public func inset(by insets: EdgeInsets) -> InsetShape<Self> {
        InsetShape(shape: self, insets: insets)
    }

    @inlinable
    public func inset(dx: CGFloat, dy: CGFloat) -> InsetShape<Self> {
        inset(by: EdgeInsets(top: dy, leading: dx, bottom: dy, trailing: dx))
    }
}

// MARK: - Previews

struct InsetShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            ZStack {
                Rectangle()
                    .inset(dx: -10, dy: -10)
                    .fill(Color.red)

                Rectangle()
                    .fill(Color.black)

                Rectangle()
                    .inset(dx: 10, dy: 10)
                    .fill(Color.blue)
            }
            .frame(width: 100, height: 100)

            ZStack {
                Capsule()
                    .inset(dx: -10, dy: -10)
                    .fill(Color.red)

                Capsule()
                    .fill(Color.black)

                Capsule()
                    .inset(dx: 10, dy: 10)
                    .fill(Color.blue)
            }
            .frame(width: 100, height: 100)

            ZStack {
                Capsule()
                    .inset(dx: -10, dy: -10)
                    .fill(Color.red)

                Capsule()
                    .fill(Color.black)

                Capsule()
                    .inset(dx: 10, dy: 10)
                    .fill(Color.blue)
            }
            .frame(width: 100, height: 40)
        }
        .padding()
    }
}
