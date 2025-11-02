//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that is applied to a ``AnyVariadicView.Element``
@MainActor @preconcurrency
public protocol VariadicViewElementModifier: DynamicProperty {

    associatedtype Body: View
    @ViewBuilder @MainActor @preconcurrency func body(content: VariadicView.Element, isSelected: Bool) -> Body
}

/// An `EmptyModifier` equivalent for a ``VariadicViewElementModifier``
@frozen
public struct VariadicViewElementEmptyModifier: VariadicViewElementModifier {
    public func body(content: VariadicView.Element, isSelected: Bool) -> some View {
        content
    }
}

@frozen
public struct VariadicViewSelectionLayout<
    ID: Hashable,
    Modifier: VariadicViewElementModifier,
>: VariadicViewLayout {

    public var selection: ID?
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

@frozen
public struct VariadicViewElementBody<
    ID: Hashable,
    Modifier: VariadicViewElementModifier
>: View {

    public var element: VariadicView.Element
    public var modifier: Modifier
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
