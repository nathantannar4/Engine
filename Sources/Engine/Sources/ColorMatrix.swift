//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A 4x5 matrix that transforms the red, green, blue and alpha components of rendered colors.
///
/// Each output component is the sum of the input components multiplied by the
/// corresponding factors, plus a constant offset. For example, the output red component is
/// `r1 * red + r2 * green + r3 * blue + r4 * alpha + r5`.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ColorMatrix: Equatable, BitwiseCopyable {

    /// The factor of the input red component in the output red component.
    public var r1: Float {
        get { matrix.m11 }
        set { matrix.m11 = newValue }
    }

    /// The factor of the input green component in the output red component.
    public var r2: Float {
        get { matrix.m12 }
        set { matrix.m12 = newValue }
    }

    /// The factor of the input blue component in the output red component.
    public var r3: Float {
        get { matrix.m13 }
        set { matrix.m13 = newValue }
    }

    /// The factor of the input alpha component in the output red component.
    public var r4: Float {
        get { matrix.m14 }
        set { matrix.m14 = newValue }
    }

    /// The constant offset added to the output red component.
    public var r5: Float {
        get { matrix.m15 }
        set { matrix.m15 = newValue }
    }

    /// The factor of the input red component in the output green component.
    public var g1: Float {
        get { matrix.m21 }
        set { matrix.m21 = newValue }
    }

    /// The factor of the input green component in the output green component.
    public var g2: Float {
        get { matrix.m22 }
        set { matrix.m22 = newValue }
    }

    /// The factor of the input blue component in the output green component.
    public var g3: Float {
        get { matrix.m23 }
        set { matrix.m23 = newValue }
    }

    /// The factor of the input alpha component in the output green component.
    public var g4: Float {
        get { matrix.m24 }
        set { matrix.m24 = newValue }
    }

    /// The constant offset added to the output green component.
    public var g5: Float {
        get { matrix.m25 }
        set { matrix.m25 = newValue }
    }

    /// The factor of the input red component in the output blue component.
    public var b1: Float {
        get { matrix.m31 }
        set { matrix.m31 = newValue }
    }

    /// The factor of the input green component in the output blue component.
    public var b2: Float {
        get { matrix.m32 }
        set { matrix.m32 = newValue }
    }

    /// The factor of the input blue component in the output blue component.
    public var b3: Float {
        get { matrix.m33 }
        set { matrix.m33 = newValue }
    }

    /// The factor of the input alpha component in the output blue component.
    public var b4: Float {
        get { matrix.m34 }
        set { matrix.m34 = newValue }
    }

    /// The constant offset added to the output blue component.
    public var b5: Float {
        get { matrix.m35 }
        set { matrix.m35 = newValue }
    }

    /// The factor of the input red component in the output alpha component.
    public var a1: Float {
        get { matrix.m41 }
        set { matrix.m41 = newValue }
    }

    /// The factor of the input green component in the output alpha component.
    public var a2: Float {
        get { matrix.m42 }
        set { matrix.m42 = newValue }
    }

    /// The factor of the input blue component in the output alpha component.
    public var a3: Float {
        get { matrix.m43 }
        set { matrix.m43 = newValue }
    }

    /// The factor of the input alpha component in the output alpha component.
    public var a4: Float {
        get { matrix.m44 }
        set { matrix.m44 = newValue }
    }

    /// The constant offset added to the output alpha component.
    public var a5: Float {
        get { matrix.m45 }
        set { matrix.m45 = newValue }
    }

    @usableFromInline
    var matrix: _ColorMatrix

    /// Creates the identity color matrix.
    @inlinable
    public init() {
        matrix = _ColorMatrix()
    }

    /// Creates a color matrix derived from a color, resolved in the given environment.
    @inlinable
    public init(color: Color, in environment: EnvironmentValues) {
        matrix = _ColorMatrix(color: color, in: environment)
    }

    /// Returns the concatenation of two color matrices.
    public static func * (lhs: Self, rhs: Self) -> Self {
        var result = ColorMatrix()
        result.matrix = lhs.matrix * rhs.matrix
        return result
    }
}

/// A modifier that transforms the colors of a view with a ``ColorMatrix``.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ColorMatrixModifier: ViewModifier, Animatable {

    /// The color matrix to apply.
    public var matrix: ColorMatrix

    /// Creates a modifier that applies a color matrix.
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

    /// Transforms the colors of the view with a ``ColorMatrix``.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func colorMatrix(_ matrix: ColorMatrix) -> some View {
        modifier(ColorMatrixModifier(matrix: matrix))
    }
}

/// A modifier that transforms the colors of a view with separate color matrices for content
/// marked with `foregroundLayer()` and for the remaining content.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct HierarchicalColorMatrixModifier: ViewModifier, Animatable {

    /// The color matrix applied to content marked with `foregroundLayer()`.
    public var foreground: ColorMatrix
    /// The color matrix applied to the remaining content.
    public var background: ColorMatrix

    /// Creates a modifier that applies separate foreground and background color matrices.
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

    /// Marks the view as foreground content for an ancestor
    /// `colorMatrix(_:background:)` modifier.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func foregroundLayer() -> some View {
        modifier(_ForegroundLayerViewModifier())
    }

    /// Transforms the colors of content marked with `foregroundLayer()` with the
    /// `foreground` color matrix, and the remaining content with the `background` color matrix.
    ///
    ///     Color.blue
    ///         .overlay(
    ///             Text("Hello, World")
    ///                 .foregroundLayer()
    ///         )
    ///         .colorMatrix(foregroundMatrix, background: backgroundMatrix)
    ///
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
