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
>: View {

    @usableFromInline
    var content: ConditionalContent<TrueContent, FalseContent>

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder else: () -> FalseContent
    ) {
        self.content = Condition.value ? .init(then()) : .init(`else`())
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

    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Condition.value
            ? TrueContent._makeView(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeView(view: view[\.falseContent], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Condition.value
            ? TrueContent._makeViewList(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeViewList(view: view[\.falseContent], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
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
        self.init(Condition.self, then: then, else: { EmptyView() })
    }
}
