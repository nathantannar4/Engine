//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ColorMatrix: Equatable, BitwiseCopyable {

    public var r1: Float {
        get { matrix.m11 }
        set { matrix.m11 = newValue }
    }

    public var r2: Float {
        get { matrix.m12 }
        set { matrix.m12 = newValue }
    }

    public var r3: Float {
        get { matrix.m13 }
        set { matrix.m13 = newValue }
    }

    public var r4: Float {
        get { matrix.m14 }
        set { matrix.m14 = newValue }
    }

    public var r5: Float {
        get { matrix.m15 }
        set { matrix.m15 = newValue }
    }

    public var g1: Float {
        get { matrix.m21 }
        set { matrix.m21 = newValue }
    }

    public var g2: Float {
        get { matrix.m22 }
        set { matrix.m22 = newValue }
    }

    public var g3: Float {
        get { matrix.m23 }
        set { matrix.m23 = newValue }
    }

    public var g4: Float {
        get { matrix.m24 }
        set { matrix.m24 = newValue }
    }

    public var g5: Float {
        get { matrix.m25 }
        set { matrix.m25 = newValue }
    }

    public var b1: Float {
        get { matrix.m31 }
        set { matrix.m31 = newValue }
    }

    public var b2: Float {
        get { matrix.m32 }
        set { matrix.m32 = newValue }
    }

    public var b3: Float {
        get { matrix.m33 }
        set { matrix.m33 = newValue }
    }

    public var b4: Float {
        get { matrix.m34 }
        set { matrix.m34 = newValue }
    }

    public var b5: Float {
        get { matrix.m35 }
        set { matrix.m35 = newValue }
    }

    public var a1: Float {
        get { matrix.m41 }
        set { matrix.m41 = newValue }
    }

    public var a2: Float {
        get { matrix.m42 }
        set { matrix.m42 = newValue }
    }

    public var a3: Float {
        get { matrix.m43 }
        set { matrix.m43 = newValue }
    }

    public var a4: Float {
        get { matrix.m44 }
        set { matrix.m44 = newValue }
    }

    public var a5: Float {
        get { matrix.m45 }
        set { matrix.m45 = newValue }
    }

    @usableFromInline
    var matrix: _ColorMatrix

    @inlinable
    public init() {
        matrix = _ColorMatrix()
    }

    @inlinable
    public init(color: Color, in environment: EnvironmentValues) {
        matrix = _ColorMatrix(color: color, in: environment)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        var result = ColorMatrix()
        result.matrix = lhs.matrix * rhs.matrix
        return result
    }
}

@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ColorMatrixModifier: ViewModifier, Animatable {

    public var matrix: ColorMatrix

    @inlinable
    public init(matrix: ColorMatrix) {
        self.matrix = matrix
    }

    public func body(content: Content) -> some View {
        content
            .modifier(_ColorMatrixEffect(matrix: matrix.matrix))
    }
}

extension View {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func colorMatrix(_ matrix: ColorMatrix) -> some View {
        modifier(ColorMatrixModifier(matrix: matrix))
    }
}

@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct HierarchicalColorMatrixModifier: ViewModifier, Animatable {

    public var foreground: ColorMatrix
    public var background: ColorMatrix

    @inlinable
    public init(foreground: ColorMatrix, background: ColorMatrix) {
        self.foreground = foreground
        self.background = background
    }

    public func body(content: Content) -> some View {
        content
            .modifier(_ForegroundLayerColorMatrixEffect(foreground: foreground.matrix, background: background.matrix))
    }
}

extension View {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func foregroundLayer() -> some View {
        modifier(_ForegroundLayerViewModifier())
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func colorMatrix(_ foreground: ColorMatrix, background: ColorMatrix) -> some View {
        modifier(HierarchicalColorMatrixModifier(foreground: foreground, background: background))
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ColorMatrix_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var baseColor = Color.blue
        @Environment(\.self) var environment

        var body: some View {
            VStack(spacing: 0) {
                baseColor

                baseColor
                    .colorMatrix(ColorMatrix(color: .white, in: environment))

                baseColor
                    .colorMatrix(ColorMatrix(color: .blue, in: environment))

                baseColor
                    .colorMatrix(ColorMatrix(color: .red, in: environment))

                Color.white
                    .colorMatrix(ColorMatrix(color: baseColor, in: environment))

                baseColor
                    .overlay(
                        Text("Hello, World")
                            .foregroundColor(baseColor)
                            .foregroundLayer()
                    )
                    .colorMatrix(ColorMatrix(color: .white, in: environment), background: ColorMatrix(color: .red, in: environment))

                baseColor
                    .overlay(
                        Text("Hello, World")
                            .foregroundColor(baseColor)
                            .foregroundLayer()
                    )
                    .colorMatrix(ColorMatrix(color: .init(white: 0.5), in: environment), background: ColorMatrix(color: .init(white: 0.75), in: environment))

                Button {
                    withAnimation {
                        baseColor = Color.random()
                    }
                } label: {
                    Text("Toggle")
                }
            }
        }
    }
}
