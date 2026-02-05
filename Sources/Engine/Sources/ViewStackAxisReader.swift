//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `View` that statically depends if its parent is a `VStack`, `HStack` or neither.
///
/// > Tip: You to make views that behave like `Divider` and `Spacer`
///
@frozen
public struct ViewStackAxisReader<
    VerticalContent: View,
    HorizontalContent: View,
    OtherContent: View,
>: View {

    @usableFromInline
    var vertical: VerticalContent

    @usableFromInline
    var horizontal: HorizontalContent

    @usableFromInline
    var other: OtherContent

    @inlinable
    public init(
        @ViewBuilder content: (Axis) -> VerticalContent
    ) where HorizontalContent == VerticalContent, OtherContent == EmptyView {
        self.vertical = content(.vertical)
        self.horizontal = content(.horizontal)
        self.other = EmptyView()
    }

    @inlinable
    public init(
        @ViewBuilder vertical: () -> VerticalContent,
        @ViewBuilder horizontal: () -> HorizontalContent,
        @ViewBuilder other: () -> OtherContent
    ) {
        self.vertical = vertical()
        self.horizontal = horizontal()
        self.other = other()
    }

    public var body: some View {
        ViewInputConditionalContent(IsAxisDefined.self) {
            ViewInputConditionalContent(IsAxisHorizontal.self) {
                horizontal
            } otherwise: {
                vertical
            }
        } otherwise: {
            other
        }
    }
}

private struct IsAxisDefined: ViewInputsCondition {
    static func evaluate(_ inputs: ViewInputs) -> Bool {
        inputs.options.contains(.isAxisDefined)
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
                ViewStackAxisReader {
                    Text("Vertical")
                } horizontal: {
                    Text("Horizontal")
                } other: {
                    Text("Other")
                }

                CustomDivider(scale: 3)

                CustomDivider()

                Divider()
                    .overlay(Color.black)
            }

            VStack {
                ViewStackAxisReader {
                    Text("Vertical")
                } horizontal: {
                    Text("Horizontal")
                } other: {
                    Text("Other")
                }

                CustomDivider()

                Divider()
            }

            LazyHStack {
                ViewStackAxisReader {
                    Text("Vertical")
                } horizontal: {
                    Text("Horizontal")
                } other: {
                    Text("Other")
                }
            }

            LazyVStack {
                ViewStackAxisReader {
                    Text("Vertical")
                } horizontal: {
                    Text("Horizontal")
                } other: {
                    Text("Other")
                }
            }

            ZStack {
                ViewStackAxisReader {
                    Text("Vertical")
                } horizontal: {
                    Text("Horizontal")
                } other: {
                    Text("Other")
                }
            }

            if #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) {
                Grid(verticalSpacing: 8) {
                    CustomDivider()

                    Divider()

                    ViewStackAxisReader {
                        Text("Vertical")
                    } horizontal: {
                        Text("Horizontal")
                    } other: {
                        Text("Other")
                    }

                    GridRow {
                        ViewStackAxisReader {
                            Text("Vertical")
                        } horizontal: {
                            Text("Horizontal")
                        } other: {
                            Text("Other")
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
