//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `Shape` from closures.
@resultBuilder
public struct ShapeBuilder {

    public static func buildBlock() -> Rectangle {
        Rectangle()
    }

    public static func buildBlock<S: Shape>(
        _ shape: S
    ) -> S {
        shape
    }

    public static func buildEither<
        TrueShape,
        FalseShape
    >(
        first: TrueShape
    ) -> ConditionalShape<TrueShape, FalseShape> {
        .init(first)
    }

    public static func buildEither<
        TrueShape,
        FalseShape
    >(
        second: FalseShape
    ) -> ConditionalShape<TrueShape, FalseShape> {
        .init(second)
    }

    public static func buildOptional<
        S: Shape
    >(
        _ shape: S?
    ) -> ConditionalShape<S, Rectangle> {
        shape.map { .init($0) } ?? .init(Rectangle())
    }

    @_disfavoredOverload
    public static func buildLimitedAvailability<S: Shape>(
        _ shape: S
    ) -> Engine.AnyShape {
        .init(shape: shape)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public static func buildLimitedAvailability<S: Shape>(
        _ shape: S
    ) -> SwiftUI.AnyShape {
        .init(shape)
    }
}

extension View {

    /// Sets a clipping shape for this view.
    @inlinable
    public func clipShape<S: Shape>(
        style: FillStyle = FillStyle(),
        @ShapeBuilder shape: () -> S
    ) -> some View {
        clipShape(shape(), style: style)
    }

    /// Defines the content shape for hit testing.
    @inlinable
    public func contentShape<S: Shape>(
        eoFill: Bool = false,
        @ShapeBuilder shape: () -> S
    ) -> some View {
        contentShape(shape(), eoFill: eoFill)
    }

    /// Sets the content shape for this view.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @inlinable
    public func contentShape<S: Shape>(
        _ kind: ContentShapeKinds,
        eoFill: Bool = false,
        @ShapeBuilder shape: () -> S
    ) -> some View {
        contentShape(kind, shape(), eoFill: eoFill)
    }
}
