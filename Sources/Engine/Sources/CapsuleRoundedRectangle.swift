//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct CapsuleRoundedRectangle: Shape, InsettableShape {

    public var maxCornerRadius: CGFloat?
    public var style: RoundedCornerStyle

    public var animatableData: CGFloat {
        get { maxCornerRadius ?? 0 }
        set { maxCornerRadius = newValue }
    }

    @inlinable
    public init(
        maxCornerRadius: CGFloat?,
        style: RoundedCornerStyle = .continuous
    ) {
        self.maxCornerRadius = maxCornerRadius
        self.style = style
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let idealCornerRadius = rect.size.height / 2
        let cornerRadius = maxCornerRadius.map { min($0, idealCornerRadius) } ?? idealCornerRadius
        return RoundedRectangle(cornerRadius: cornerRadius, style: style).path(in: rect)
    }

    public nonisolated func inset(by amount: CGFloat) -> InsetShape<Self> {
        return inset(dx: amount, dy: amount)
    }
}

// MARK: - Previews

struct CapsuleRoundedRectangle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            let maxCornerRadius: CGFloat? = flag ? nil : 10
            VStack {
                HStack {
                    Capsule()

                    CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius)
                }
                .frame(height: 50)

                HStack {
                    Capsule()
                        .inset(by: 10)

                    CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius)
                        .inset(by: 10)
                }
                .frame(height: 50)

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
