//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `ViewModifier` that is statically either `TrueModifier` or `FalseModifier`.
@frozen
public struct ViewInputConditionalModifier<
    Condition: ViewInputsCondition,
    TrueModifier: ViewModifier,
    FalseModifier: ViewModifier
>: PrimitiveViewModifier {

    @usableFromInline
    var trueModifier: TrueModifier

    @usableFromInline
    var falseModifier: FalseModifier

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewModifierBuilder then: () -> TrueModifier,
        @ViewModifierBuilder otherwise: () -> FalseModifier
    ) {
        self.trueModifier = then()
        self.falseModifier = otherwise()
    }

    @inlinable
    public init(
        _ : Condition,
        @ViewModifierBuilder then: () -> TrueModifier,
        @ViewModifierBuilder otherwise: () -> FalseModifier
    ) {
        self.trueModifier = then()
        self.falseModifier = otherwise()
    }

    public static func makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        Condition.evaluate(ViewInputs(inputs: inputs._graphInputs))
            ? TrueModifier._makeView(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
            : FalseModifier._makeView(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    public static func makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        Condition.evaluate(ViewInputs(inputs: inputs._graphInputs))
            ? TrueModifier._makeViewList(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
            : FalseModifier._makeViewList(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        Condition.evaluate(ViewInputs(inputs: inputs._graphInputs))
            ? TrueModifier._viewListCount(inputs: inputs, body: body)
            : FalseModifier._viewListCount(inputs: inputs, body: body)
    }
}

extension ViewInputConditionalModifier where FalseModifier == EmptyModifier {
    public init(
        _ : Condition.Type = Condition.self,
        @ViewModifierBuilder then: () -> TrueModifier
    ) {
        self.init(Condition.self, then: then, otherwise: { EmptyModifier() })
    }

    public init(
        _ : Condition,
        @ViewModifierBuilder then: () -> TrueModifier
    ) {
        self.init(Condition.self, then: then, otherwise: { EmptyModifier() })
    }
}

// MARK: - Previews

struct ViewInputConditionalModifier_Previews: PreviewProvider {
    struct PreviewFlag: ViewInputFlag { }
    struct BorderModifier: ViewModifier {
        func body(content: Content) -> some View {
            content.border(Color.red)
        }
    }

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(
                    ViewInputConditionalModifier(PreviewFlag.self) {
                        BorderModifier()
                    }
                )
                .input(PreviewFlag.self)
        }
    }
}
