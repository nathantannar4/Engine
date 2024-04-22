//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `View` that statically depends if its parent is a `VStack` or `HStack`.
///
/// > Tip: You to make views that behave like `Divider` and `Spacer`
///
@frozen
public struct ViewStackAxisReader<Content: View>: View {

    @usableFromInline
    var vertical: Content

    @usableFromInline
    var horizontal: Content

    @inlinable
    public init(
        @ViewBuilder content: (Axis) -> Content
    ) {
        self.vertical = content(.vertical)
        self.horizontal = content(.horizontal)
    }

    public var body: some View {
        ViewInputConditionalContent(IsAxisHorizontal.self) {
            horizontal
        } otherwise: {
            vertical
        }
    }
}

private struct IsAxisHorizontal: ViewInputsCondition {
    static func evaluate(_ inputs: ViewInputs) -> Bool {
        inputs.options.contains(.isAxisHorizontal)
    }
}

// MARK: - Previews

private struct CustomDivider: View {

    var scale: CGFloat = 1

    @Environment(\.pixelLength) var pixelLength

    var body: some View {
        ViewStackAxisReader { axis in
            Capsule(style: .circular)
                .frame(
                    width: axis == .horizontal ? scale * pixelLength : nil,
                    height: axis == .vertical ? scale * pixelLength : nil
                )
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ViewStackAxisReader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            HStack {
                ViewStackAxisReader { axis in
                    Text(axis == .horizontal ? "Horizontal" : "Vertical")
                }

                CustomDivider(scale: 3)

                CustomDivider()

                Divider()
                    .overlay(Color.black)
            }

            VStack {
                ViewStackAxisReader { axis in
                    Text(axis == .horizontal ? "Horizontal" : "Vertical")
                }

                CustomDivider()

                Divider()
            }

            LazyHStack {
                ViewStackAxisReader { axis in
                    Text(axis == .horizontal ? "Horizontal" : "Vertical")
                }
            }

            LazyVStack {
                ViewStackAxisReader { axis in
                    Text(axis == .horizontal ? "Horizontal" : "Vertical")
                }
            }

            ZStack {
                ViewStackAxisReader { axis in
                    Text(axis == .horizontal ? "Horizontal" : "Vertical")
                }
            }

            if #available(iOS 16.0, macOS 13.0, *) {
                Grid(verticalSpacing: 8) {
                    CustomDivider()

                    Divider()

                    ViewStackAxisReader { axis in
                        Text(axis == .horizontal ? "Horizontal" : "Vertical")
                    }

                    GridRow {
                        ViewStackAxisReader { axis in
                            Text(axis == .horizontal ? "Horizontal" : "Vertical")
                        }

                        CustomDivider()

                        Divider()
                    }
                }
            }
        }
        .fixedSize()
    }
}
