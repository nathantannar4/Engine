//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a layout from closures.
///
/// ```
/// var axis: Axis
///
/// @LayoutBuilder
/// var layout: some Layout {
///     switch axis {
///     case .vertical:
///         VStackLayout()
///     case .horizontal:
///         HStackLayout()
///     }
/// }
/// ```
@resultBuilder
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct LayoutBuilder {
    public static func buildBlock() -> VStackLayout {
        VStackLayout()
    }

    public static func buildBlock<L: Layout>(
        _ layout: L
    ) -> L {
        layout
    }

    public static func buildEither<
        TrueLayout: Layout,
        FalseLayout: Layout
    >(
        first: TrueLayout
    ) -> ConditionalLayout<TrueLayout, FalseLayout> {
        ConditionalLayout(first)
    }

    public static func buildEither<
        TrueLayout: Layout,
        FalseLayout: Layout
    >(
        second: FalseLayout
    ) -> ConditionalLayout<TrueLayout, FalseLayout> {
        ConditionalLayout(second)
    }
}
