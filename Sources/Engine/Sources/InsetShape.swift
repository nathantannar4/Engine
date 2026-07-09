//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct InsetShape<S: Shape>: Shape, InsettableShape, Animatable {

    public var shape: S
    public var insets: EdgeInsets

    public var animatableData: AnimatablePair<S.AnimatableData, EdgeInsets.AnimatableData> {
        get {
            AnimatablePair(
                shape.animatableData,
                insets.animatableData
            )
        }
        set {
            shape.animatableData = newValue.first
            insets.animatableData = newValue.second
        }
    }

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

    public nonisolated func inset(
        by amount: CGFloat
    ) -> InsetShape<S> {
        var insets = insets
        insets.top += amount
        insets.bottom += amount
        insets.leading += amount
        insets.trailing += amount
        return InsetShape(shape: shape, insets: insets)
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension InsetShape: RoundedRectangularShape where S: RoundedRectangularShape {

    public func corners(in size: CGSize?) -> Corners? {
        if var size {
            size.width -= (insets.leading + insets.trailing)
            size.height -= (insets.top + insets.bottom)
            return shape.corners(in: size)
        }
        return shape.corners(in: size)
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
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            let inset: CGFloat = flag ? 20 : 10
            VStack(spacing: 48) {
                ZStack {
                    Rectangle()
                        .inset(dx: -inset, dy: -inset)
                        .fill(Color.red)

                    Rectangle()
                        .fill(Color.black)

                    Rectangle()
                        .inset(dx: inset, dy: inset)
                        .fill(Color.blue)
                }
                .frame(width: 100, height: 100)

                ZStack {
                    Capsule()
                        .inset(dx: -inset, dy: -inset)
                        .fill(Color.red)

                    Capsule()
                        .fill(Color.black)

                    Capsule()
                        .inset(dx: inset, dy: inset)
                        .fill(Color.blue)
                }
                .frame(width: 100, height: 100)

                ZStack {
                    Capsule()
                        .inset(dx: -inset, dy: -inset)
                        .fill(Color.red)

                    Capsule()
                        .fill(Color.black)

                    Capsule()
                        .inset(dx: inset, dy: inset)
                        .fill(Color.blue)
                }
                .frame(width: 100, height: 60)

                ZStack {
                    Circle()
                        .inset(dx: -inset, dy: -inset)
                        .inset(dx: -inset, dy: -inset)
                        .fill(Color.red)

                    Circle()
                        .fill(Color.black)

                    Circle()
                        .inset(dx: inset, dy: inset)
                        .inset(dx: inset, dy: inset)
                        .fill(Color.blue)
                }
                .frame(width: 100, height: 100)

                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }
            }
            .padding()
        }
    }
}
