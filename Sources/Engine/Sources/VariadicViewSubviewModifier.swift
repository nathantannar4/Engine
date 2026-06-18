//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public protocol VariadicViewSubviewModifier: DynamicProperty {
    associatedtype ID: Hashable
    associatedtype Body: View

    @ViewBuilder @MainActor @preconcurrency func body(content: Content) -> Body

    typealias Content = VariadicViewSubviewModifierContent<ID>
}

@frozen
public struct VariadicViewSubviewModifierContent<ID: Hashable>: View {

    public var id: ID
    public var index: Int
    public var subview: VariadicView.Subview

    public var body: some View {
        subview
    }
}

@frozen
public struct VariadicViewModifiedSubview<Modifier: VariadicViewSubviewModifier>: View {

    public var content: VariadicViewSubviewModifierContent<Modifier.ID>
    public var modifier: Modifier

    public var body: some View {
        modifier.body(content: content)
    }
}

extension VariadicView {

    public func modifier<
        Modifier: VariadicViewSubviewModifier
    >(
        _ modifier: Modifier
    ) -> some View {
        let id: KeyPath<VariadicView.Subview, Modifier.ID> = .selection(Modifier.ID.self)
        return ForEachSubview(self, id: id) { index, subview in
            VariadicViewModifiedSubview(
                content: VariadicViewSubviewModifierContent(
                    id: subview[keyPath: id],
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
