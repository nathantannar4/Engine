//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is statically either `TrueContent` or `FalseContent`.
@frozen
public struct StaticConditionalContent<
    Condition: StaticCondition,
    TrueContent: View,
    FalseContent: View
>: PrimitiveView {

    @usableFromInline
    var content: ConditionalContent<TrueContent, FalseContent>

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder otherwise: () -> FalseContent
    ) {
        self.content = Condition.value ? .init(then()) : .init(otherwise())
    }

    private var trueContent: TrueContent {
        switch content.storage {
        case .trueContent(let content):
            return content
        case .falseContent:
            fatalError("Condition \(String(describing: Condition.self)) produced a dynamic result")
        }
    }

    private var falseContent: FalseContent {
        switch content.storage {
        case .trueContent:
            fatalError("Condition \(String(describing: Condition.self)) produced a dynamic result")
        case .falseContent(let content):
            return content
        }
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Condition.value
            ? TrueContent._makeView(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeView(view: view[\.falseContent], inputs: inputs)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Condition.value
            ? TrueContent._makeViewList(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeViewList(view: view[\.falseContent], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        Condition.value
            ? TrueContent._viewListCount(inputs: inputs)
            : FalseContent._viewListCount(inputs: inputs)
    }
}

extension StaticConditionalContent where FalseContent == EmptyView {
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(Condition.self, then: then, otherwise: { EmptyView() })
    }
}

// MARK: - Previews

struct StaticConditionalContent_Previews: PreviewProvider {
    struct PreviewCondition: StaticCondition {
        static var value: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }

    static var previews: some View {
        StaticConditionalContent(PreviewCondition.self) {
            Text("DEBUG")
        }

        StaticConditionalContent(PreviewCondition.self) {
            Text("DEBUG")
        } otherwise: {
            Text("!DEBUG")
        }
    }
}
