//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct CapsuleRoundedRectangle: Shape, InsettableShape, RoundedRectangularShape {

    @frozen
    public enum Style: Hashable, Sendable {
        case rounded(RoundedCornerStyle)

        /// Resolves to `.continuous` when capped by the maximum corner radius
        case automatic
    }

    public var maxCornerRadius: CGFloat?
    public var style: Style

    private var inset: CGFloat = 0

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(maxCornerRadius ?? 0, inset)
        }
        set {
            maxCornerRadius = newValue.first
            inset = newValue.second
        }
    }

    @inlinable
    public init(
        maxCornerRadius: CGFloat?,
        style: RoundedCornerStyle
    ) {
        self.init(maxCornerRadius: maxCornerRadius, style: .rounded(style))
    }

    @inlinable
    public init(
        maxCornerRadius: CGFloat?,
        style: Style = .automatic
    ) {
        self.maxCornerRadius = maxCornerRadius
        self.style = style
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let cornerRadius = cornerRadius(height: rect.size.height)
        let insetRect = rect.insetBy(dx: inset, dy: inset)
        let style = roundedCornerStyle(cornerRadius: cornerRadius)
        return RoundedRectangle(cornerRadius: cornerRadius, style: style).path(in: insetRect)
    }

    public nonisolated func inset(by amount: CGFloat) -> CapsuleRoundedRectangle {
        var copy = self
        copy.inset += amount
        return copy
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public func corners(in size: CGSize?) -> Corners? {
        if let size {
            let cornerRadius = cornerRadius(height: size.height)
            let style = roundedCornerStyle(cornerRadius: cornerRadius)
            return RoundedRectangle(cornerRadius: cornerRadius, style: style).corners(in: size)
        }
        return .concentric
    }

    private func cornerRadius(height: CGFloat) -> CGFloat {
        let idealCornerRadius = height / 2
        let cornerRadius = maxCornerRadius.map { min($0, idealCornerRadius) } ?? idealCornerRadius
        return cornerRadius - inset
    }

    private func roundedCornerStyle(cornerRadius: CGFloat) -> RoundedCornerStyle {
        switch style {
        case .rounded(let style):
            return style
        case .automatic:
            guard
                let maxCornerRadius,
                cornerRadius < maxCornerRadius
            else {
                return .continuous
            }
            return .circular
        }
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

                    RoundedRectangle(cornerRadius: maxCornerRadius ?? 0)
                }
                .frame(height: 50)

                HStack {
                    Capsule()
                        .inset(by: 5)

                    CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius)
                        .inset(by: 5)

                    RoundedRectangle(cornerRadius: maxCornerRadius ?? 0)
                        .inset(by: 5)
                }
                .frame(height: 50)

                #if canImport(FoundationModels) && !os(visionOS) // Xcode 26
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                    VStack {
                        Text("Hello, World")
                            .padding()
                            .glassEffect(
                                .regular.interactive().tint(.blue),
                                in: CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius ?? 0)
                            )

                        HStack {
                            Text("Hello, World")
                                .padding()
                                .glassEffect(
                                    .regular.interactive().tint(.blue),
                                    in: CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius ?? 0).inset(by: -5)
                                )

                            Text("Hello, World")
                                .padding()
                                .glassEffect(
                                    .regular.interactive().tint(.blue),
                                    in: CapsuleRoundedRectangle(maxCornerRadius: maxCornerRadius ?? 0).inset(by: 5)
                                )
                        }

                        HStack {
                            Text("Hello, World")
                                .padding()
                                .glassEffect(
                                    .regular.interactive().tint(.blue),
                                    in: RoundedRectangle(cornerRadius: 40) // Has issues
                                )

                            Text("Hello, World")
                                .padding()
                                .glassEffect(
                                    .regular.interactive().tint(.blue),
                                    in: CapsuleRoundedRectangle(maxCornerRadius: 40)
                                )
                        }
                    }
                }
                #endif

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
