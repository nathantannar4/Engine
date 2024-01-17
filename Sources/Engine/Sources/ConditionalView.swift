//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is dynamically either `TrueContent` or `FalseContent`.
public typealias ConditionalView<TrueContent: View, FalseContent: View> = ConditionalContent<TrueContent, FalseContent>

extension ConditionalView: View where TrueContent: View, FalseContent: View {
    @inlinable
    public init(
        if condition: Bool,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder otherwise: () -> FalseContent
    ) {
        self.storage = condition ? .trueContent(then()) : .falseContent(otherwise())
    }

    public var body: some View {
        switch storage {
        case .trueContent(let trueContent):
            trueContent
        case .falseContent(let falseContent):
            falseContent
        }
    }
}

extension ConditionalView where TrueContent: View, FalseContent == EmptyView {
    @inlinable
    public init(
        if condition: Bool,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(if: condition, then: then, otherwise: { EmptyView() })
    }
}

// MARK: - Previews

struct ConditionalView_Previews: PreviewProvider {
    struct Preview: View {
        @State var condition = true

        var body: some View {
            VStack {
                Toggle(
                    isOn: $condition.animation(.default),
                    label: { EmptyView() }
                )
                .labelsHidden()

                ConditionalContent(if: condition) {
                    VStack {
                        content
                    }
                } otherwise: {
                    HStack {
                        content
                    }
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
