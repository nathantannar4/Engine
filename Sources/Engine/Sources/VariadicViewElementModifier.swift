//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that is applied to each subview of a ``VariadicView``, with knowledge of whether the subview is selected.
public protocol VariadicViewElementModifier: DynamicProperty {

    /// The type of view representing the body.
    associatedtype Body: View
    /// Returns the modified subview.
    ///
    /// - Parameters:
    ///   - content: The subview to modify.
    ///   - isSelected: Whether the selection value of the subview matches the current selection.
    @ViewBuilder @MainActor @preconcurrency func body(content: VariadicView.Element, isSelected: Bool) -> Body
}

/// An `EmptyModifier` equivalent for a ``VariadicViewElementModifier``.
@frozen
public struct VariadicViewElementEmptyModifier: VariadicViewElementModifier {
    public func body(content: VariadicView.Element, isSelected: Bool) -> some View {
        content
    }
}

/// A ``VariadicViewLayout`` that applies a ``VariadicViewElementModifier`` to each subview,
/// indicating whether the subview's selection value matches `selection`.
@frozen
public struct VariadicViewSelectionLayout<
    ID: Hashable,
    Modifier: VariadicViewElementModifier,
>: VariadicViewLayout {

    /// The currently selected value.
    public var selection: ID?
    /// The modifier applied to each subview.
    public var modifier: Modifier

    init(
        selection: ID? = nil,
        modifier: Modifier
    ) {
        self.selection = selection
        self.modifier = modifier
    }

    public func body(children: VariadicView) -> some View {
        ForEach(children) { child in
            VariadicViewElementBody(
                element: child,
                modifier: modifier,
                selection: selection
            )
        }
    }
}

/// A view that applies a ``VariadicViewElementModifier`` to a subview,
/// indicating whether the subview's selection value matches `selection`.
@frozen
public struct VariadicViewElementBody<
    ID: Hashable,
    Modifier: VariadicViewElementModifier
>: View {

    /// The subview to modify.
    public var element: VariadicView.Element
    /// The modifier applied to the subview.
    public var modifier: Modifier
    /// The currently selected value.
    public var selection: ID?

    @inlinable
    init(
        element: VariadicView.Element,
        modifier: Modifier,
        selection: ID? = nil
    ) {
        self.element = element
        self.modifier = modifier
        self.selection = selection
    }

    public var body: some View {
        modifier.body(content: element, isSelected: selection == element.selection(as: ID.self))
    }
}

// MARK: - Previews

struct VariadicViewElementModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Modifier: VariadicViewElementModifier {
        func body(content: VariadicView.Element, isSelected: Bool) -> some View {
            content
                .padding(isSelected ? 8 : 0)
                .border(isSelected ? Color.accentColor : .clear, width: 2)
        }
    }

    struct Preview: View {
        @State var selection: Int = 0

        var body: some View {
            HStack {
                VariadicViewVisitor(
                    layout: VariadicViewSelectionLayout(
                        selection: selection,
                        modifier: Modifier()
                    )
                ) {
                    Button {
                        withAnimation {
                            selection = 0
                        }
                    } label: {
                        Text("Zero")
                    }
                    .tag(0)

                    ForEach(1...3, id: \.self) { id in
                        Button {
                            withAnimation {
                                selection = id
                            }
                        } label: {
                            Text("Index \(id)")
                        }
                    }
                }
            }
        }
    }
}
