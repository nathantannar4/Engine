//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that encapsulates the use of a ``LayoutBuilder``.
///
/// ```
/// struct HVStack<Content: View>: View {
///     var axis: Axis
///     var content: Content
///
///     var body: some View {
///         LayoutAdapter {
///             switch axis {
///             case .vertical:
///                 VStackLayout()
///             case .horizontal:
///                 HStackLayout()
///             }
///         } content: {
///             content
///         }
///     }
/// }
/// ```
/// 
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct LayoutAdapter<L: Layout, Content: View>: View {

    @usableFromInline
    var layout: L

    @usableFromInline
    var content: Content

    @inlinable
    public init(
        @LayoutBuilder layout: () -> L,
        @ViewBuilder content: () -> Content
    ) {
        self.layout = layout()
        self.content = content()
    }

    public var body: some View {
        layout {
            content
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct LayoutAdapter_Previews: PreviewProvider {
    struct Preview: View {
        @State var condition = true

        var body: some View {
            VStack {
                Toggle(
                    isOn: $condition.animation(.default),
                    label: { EmptyView() }
                )
                .labelsHidden()

                LayoutAdapter {
                    if condition {
                        VStackLayout()
                    } else {
                        HStackLayout()
                    }
                } content: {
                    content
                }
            }
        }

        @ViewBuilder
        var content: some View {
            Text("Hello")
            Text("World")
        }
    }

    static var previews: some View {
        Preview()
    }
}
