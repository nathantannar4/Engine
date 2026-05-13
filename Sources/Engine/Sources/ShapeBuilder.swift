//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `Shape` from closures.
@resultBuilder
public struct ShapeBuilder {

    public static func buildBlock() -> EmptyShape {
        EmptyShape()
    }

    public static func buildPartialBlock(
        first: Void
    ) -> EmptyShape { EmptyShape() }

    public static func buildPartialBlock(
        first: Never
    ) -> EmptyShape { }

    public static func buildBlock<S: Shape>(
        _ shape: S
    ) -> S {
        shape
    }

    public static func buildBlock<S: Shape>(
        _ shape: S?
    ) -> EmptyShape {
        EmptyShape()
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
    ) -> OptionalShape<S> {
        OptionalShape(shape)
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

    /// Masks this view using the alpha channel of the given view.
    @inlinable
    @_disfavoredOverload
    public func mask<S: Shape>(
        alignment: Alignment = .center,
        @ShapeBuilder shape: () -> S
    ) -> some View {
        mask(alignment: alignment) {
            _ShapeView(shape: shape(), style: Color.black)
        }
    }

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

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @inlinable
    public func containerShape<S: InsettableShape>(
        @ShapeBuilder shape: () -> S
    ) -> some View {
        containerShape(shape())
    }
}

// MARK: - Previews


struct ShapeBuilder_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = true

        var body: some View {
            VStack {
                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }

                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .clipShape {
                            Circle()
                        }

                    Rectangle()
                        .fill(Color.yellow)
                        .clipShape {
                            if flag {
                                Circle()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }

                    Rectangle()
                        .fill(Color.red)
                        .overlay(
                            ZStack(alignment: .topLeading) {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .offset(x: -15, y: -15)
                            },
                            alignment: .topLeading
                        )
                        .clipShape {
                            if !flag {
                                RoundedRectangle(cornerRadius: 12)
                            }
                        }
                }

                HStack {
                    Rectangle()
                        .clipShape {
                            // Empty
                        }

                    let s: Circle? = nil
                    Rectangle()
                        .clipShape {
                            s
                        }
                }

                HStack {
                    Rectangle()
                        .mask {
                            // Empty
                        }

                    let s: Circle? = nil
                    Rectangle()
                        .mask {
                            s
                        }
                }
            }
        }
    }
}
