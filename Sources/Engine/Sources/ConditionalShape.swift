//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A shape that is dynamically either `TrueLayout` or `FalseLayout`.
public typealias ConditionalShape<TrueShape: Shape, FalseShape: Shape> = ConditionalContent<TrueShape, FalseShape>

extension ConditionalShape: Shape {

    public func path(in rect: CGRect) -> Path {
        switch storage {
        case .trueContent(let shape):
            return shape.path(in: rect)
        case .falseContent(let shape):
            return shape.path(in: rect)
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var role: ShapeRole {
        if TrueContent.role == FalseContent.role {
            return TrueContent.role
        }
        return EmptyShape.role
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior {
        switch storage {
        case .trueContent(let shape):
            return shape.layoutDirectionBehavior
        case .falseContent(let shape):
            return shape.layoutDirectionBehavior
        }
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        switch storage {
        case .trueContent(let shape):
            return shape.sizeThatFits(proposal)
        case .falseContent(let shape):
            return shape.sizeThatFits(proposal)
        }
    }
}

// MARK: - Previews

struct ConditionalShape_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var flag = true

        var body: some View {
            VStack {
                Color.red
                    .clipShape(
                        ConditionalShape(if: flag) {
                            Circle()
                        } otherwise: {
                            Rectangle()
                        }
                    )

                ConditionalShape(if: flag) {
                    Circle()
                } otherwise: {
                    Rectangle()
                }
                .fill(Color.red)

                ConditionalShape(if: flag) {
                    Circle()
                } otherwise: {
                    RoundedRectangle(cornerRadius: 25.0)
                }
                .fill(Color.red)

                ConditionalShape(if: flag) {
                    RoundedRectangle(cornerRadius: 25.0)
                } otherwise: {
                    Rectangle()
                }
                .fill(Color.red)

                ConditionalShape(if: flag) {
                    RoundedRectangle(cornerRadius: 25)
                } otherwise: {
                    RoundedRectangle(cornerRadius: 0)
                }
                .fill(Color.red)
            }
            .padding()
            .onTapGesture {
                withAnimation {
                    flag.toggle()
                }
            }
        }
    }
}
