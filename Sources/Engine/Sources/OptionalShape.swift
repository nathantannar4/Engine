//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// The optional shape
@frozen
public struct OptionalShape<S: Shape>: Shape {

    public var shape: S?

    public var animatableData: AnyAnimatableData {
        get {
            if let shape {
                return AnyAnimatableData(shape.animatableData)
            }
            return AnyAnimatableData(EmptyAnimatableData())
        }
        set {
            if let newValue = newValue.as(S.AnimatableData.self) {
                shape?.animatableData = newValue
            }
        }
    }

    @inlinable
    public init(
        _ shape: S?
    ) {
        self.shape = shape
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public nonisolated static var role: ShapeRole {
        S.role
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior {
        shape?.layoutDirectionBehavior ?? .mirrors
    }

    public func path(in rect: CGRect) -> Path {
        if let shape {
            return shape.path(in: rect)
        }
        return EmptyShape().path(in: rect)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        if let shape {
            return shape.sizeThatFits(proposal)
        }
        return EmptyShape().sizeThatFits(proposal)
    }
}

extension OptionalShape: InsettableShape where S: InsettableShape {

    public func inset(by amount: CGFloat) -> OptionalShape<S.InsetShape> {
        let shape = shape?.inset(by: amount)
        return OptionalShape<S.InsetShape>(shape)
    }
}

// MARK: - Previews

struct OptionalShape_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }

                OptionalShape<RoundedRectangle>(RoundedRectangle(cornerRadius: flag ? 12 : 36))
                    .fill(Color.red)
                    .frame(width: 100, height: 100)

                HStack {
                    OptionalShape<RoundedRectangle>(flag ? RoundedRectangle(cornerRadius: 12) : nil)
                        .fill(Color.red)
                        .frame(width: 100, height: 100)

                    OptionalShape<RoundedRectangle>(flag ? nil :  RoundedRectangle(cornerRadius: 12))
                        .fill(Color.red)
                        .frame(width: 100, height: 100)
                }

                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .clipShape {
                            if flag {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .clipShape {
                            if !flag {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }
                }

                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.25)
                        .clipShape {
                            if flag {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.25)
                        .clipShape {
                            if !flag {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }
                }
            }
        }
    }
}
