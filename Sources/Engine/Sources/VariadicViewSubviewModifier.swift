//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that is applied to each subview of a ``VariadicView`` that has a selection value of type `ID`.
///
/// Since a ``VariadicViewSubviewModifier`` is a `DynamicProperty`, it can contain
/// property wrappers such as `@State`, which is kept per subview.
///
/// See ``VariadicView/modifier(_:)``.
public protocol VariadicViewSubviewModifier: DynamicProperty {
    /// The selection value type of the subviews, from their tag or `.id(...)`.
    associatedtype ID: Hashable
    /// The type of view representing the body.
    associatedtype Body: View

    /// Returns the modified subview.
    @ViewBuilder @MainActor @preconcurrency func body(content: Content) -> Body

    /// The content subview to be modified.
    typealias Content = VariadicViewSubviewModifierContent<ID>
}

/// A subview that is modified by a ``VariadicViewSubviewModifier``.
@frozen
public struct VariadicViewSubviewModifierContent<ID: Hashable>: View {

    /// The selection value of the subview.
    public var id: ID
    /// The index of the subview.
    public var index: Int
    /// The subview.
    public var subview: VariadicView.Subview

    public var body: some View {
        subview
    }
}

/// A view that applies a ``VariadicViewSubviewModifier`` to a subview.
@frozen
public struct VariadicViewModifiedSubview<Modifier: VariadicViewSubviewModifier>: View {

    /// The subview to modify.
    public var content: VariadicViewSubviewModifierContent<Modifier.ID>
    /// The modifier applied to the subview.
    public var modifier: Modifier

    public var body: some View {
        modifier.body(content: content)
    }
}

extension VariadicView {

    /// Applies `modifier` to each subview.
    ///
    /// Subviews that do not have a tag or `.id(...)` of type `Modifier.ID` are
    /// filtered out.
    public func modifier<
        Modifier: VariadicViewSubviewModifier
    >(
        _ modifier: Modifier
    ) -> some View {
        ForEachSubview(self, id: .selection(Modifier.ID.self)) { index, subview in
            VariadicViewModifiedSubview(
                content: VariadicViewSubviewModifierContent(
                    id: subview[keyPath: KeyPath<VariadicView.Subview, Modifier.ID>.selection(Modifier.ID.self)],
                    index: index,
                    subview: subview
                ),
                modifier: modifier
            )
        }
    }
}

// MARK: - Previews

struct VariadicViewSubviewModifier_Previews: PreviewProvider {

    enum PreviewCase: String, CaseIterable {
        case one
        case two
        case three
    }

    struct PreviewModifier: VariadicViewSubviewModifier {
        typealias ID = PreviewCase

        @State var flag = false

        func body(content: Content) -> some View {
            Button {
                withAnimation {
                    flag.toggle()
                }
            } label: {
                HStack {
                    Text(content.index.description)

                    Text(content.id.rawValue)

                    content
                }
            }
            .border(flag ? Color.green : Color.red, width: 1)
        }
    }

    static var previews: some View {
        ZStack {
            VStack {
                VariadicViewAdapter {
                    Text("Line 1").tag(PreviewCase.one)
                    Text("Line 2").tag(PreviewCase.two)
                    Text("Line 3") // Filtered out
                } content: { source in
                    source
                        .modifier(PreviewModifier())
                }
            }
        }
        .previewDisplayName("Tag")

        ZStack {
            VStack {
                VariadicViewAdapter {
                    ForEach(PreviewCase.allCases, id: \.self) { index, id in
                        Text("Line \(index + 1)")
                    }
                } content: { source in
                    source
                        .modifier(PreviewModifier())
                }
            }
        }
        .previewDisplayName("ForEach")
    }
}
