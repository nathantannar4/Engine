//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct ShapeAdapter<S: Shape>: Shape {

    @usableFromInline
    var shape: S

    public var animatableData: S.AnimatableData {
        get { shape.animatableData }
        set { shape.animatableData = newValue }
    }

    @inlinable
    public init(@ShapeBuilder shape: () -> S) {
        self.shape = shape()
    }

    public func path(in rect: CGRect) -> Path {
        shape.path(in: rect)
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

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct ShapeAdapter_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isCircle = true

        var body: some View {
            VStack {
                ShapeAdapter {
                    Circle()
                }
                .fill(Color.red)

                ShapeAdapter {
                    Rectangle()
                }
                .fill(Color.red)

                ShapeAdapter {
                    RoundedRectangle(cornerRadius: 12)
                }
                .fill(Color.red)


                ShapeAdapter {
                    RoundedRectangle(cornerRadius: isCircle ? 25 : 0)
                }
                .fill(Color.red)

                ShapeAdapter {
                    if isCircle {
                        Circle()
                    } else {
                        Rectangle()
                    }
                }
                .fill(Color.red)

                Color.red
                    .clipShape {
                        if isCircle {
                            Circle()
                        } else {
                            Rectangle()
                        }
                    }

                Color.red
                    .clipShape {
                        if isCircle {
                            Circle()
                        }
                    }
            }
            .padding()
            .onTapGesture {
                withAnimation {
                    isCircle.toggle()
                }
            }
        }
    }
}
