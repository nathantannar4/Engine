//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `ViewModifier` that is statically either `TrueModifier` or `FalseModifier`.
@frozen
public struct StaticConditionalModifier<
    Condition: StaticCondition,
    TrueModifier: ViewModifier,
    FalseModifier: ViewModifier
>: ViewModifier {

    @frozen
    @usableFromInline
    enum Storage {
        case trueModifier(TrueModifier)
        case falseModifier(FalseModifier)
    }

    @usableFromInline
    var storage: Storage

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewModifierBuilder then: () -> TrueModifier,
        @ViewModifierBuilder else: () -> FalseModifier
    ) {
        self.storage = Condition.value ? .trueModifier(then()) : .falseModifier(`else`())
    }

    var trueModifier: TrueModifier {
        switch storage {
        case .trueModifier(let content):
            return content
        case .falseModifier:
            fatalError("Condition \(String(describing: Condition.self)) produced a dynamic result")
        }
    }

    var falseModifier: FalseModifier {
        switch storage {
        case .trueModifier:
            fatalError("Condition \(String(describing: Condition.self)) produced a dynamic result")
        case .falseModifier(let content):
            return content
        }
    }

    public func body(content: Content) -> Never {
        bodyError()
    }

    public static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        Condition.value
            ? TrueModifier._makeView(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
            : FalseModifier._makeView(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    public static func _makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        Condition.value
            ? TrueModifier._makeViewList(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
            : FalseModifier._makeViewList(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        Condition.value
            ? TrueModifier._viewListCount(inputs: inputs, body: body)
            : FalseModifier._viewListCount(inputs: inputs, body: body)
    }
}

extension StaticConditionalModifier where Condition: StaticCondition, FalseModifier == EmptyModifier {
    public init(
        _ : Condition.Type = Condition.self,
        @ViewModifierBuilder then: () -> TrueModifier
    ) {
        self.init(Condition.self, then: then, else: { EmptyModifier() })
    }
}
