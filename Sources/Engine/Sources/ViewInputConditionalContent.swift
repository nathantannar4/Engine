//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that is statically either `TrueContent` or `FalseContent`.
@frozen
public struct ViewInputConditionalContent<
    Condition: ViewInputsCondition,
    TrueContent: View,
    FalseContent: View
>: View {
    @usableFromInline
    var trueContent: TrueContent

    @usableFromInline
    var falseContent: FalseContent

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder else: () -> FalseContent
    ) {
        self.trueContent = then()
        self.falseContent = `else`()
    }

    public var body: Never {
        bodyError()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Condition.evaluate(inputs.base)
        ? TrueContent._makeView(view: view[\.trueContent], inputs: inputs)
        : FalseContent._makeView(view: view[\.falseContent], inputs: inputs)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Condition.evaluate(inputs.base)
        ? TrueContent._makeViewList(view: view[\.trueContent], inputs: inputs)
        : FalseContent._makeViewList(view: view[\.falseContent], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        Condition.evaluate(inputs.base)
        ? TrueContent._viewListCount(inputs: inputs)
        : FalseContent._viewListCount(inputs: inputs)
    }
}

extension ViewInputConditionalContent where FalseContent == EmptyView {
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(Condition.self, then: then, else: { EmptyView() })
    }
}

/// A `ViewModifier` that is statically either `TrueModifier` or `FalseModifier`.
@frozen
public struct ViewInputConditionalModifier<
    Condition: ViewInputsCondition,
    TrueModifier: ViewModifier,
    FalseModifier: ViewModifier
>: ViewModifier {
    @usableFromInline
    var trueModifier: TrueModifier

    @usableFromInline
    var falseModifier: FalseModifier

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        then: TrueModifier,
        else: FalseModifier
    ) {
        self.trueModifier = then
        self.falseModifier = `else`
    }

    public func body(content: Content) -> Never {
        bodyError()
    }

    public static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        Condition.evaluate(inputs.base)
        ? TrueModifier._makeView(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
        : FalseModifier._makeView(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    public static func _makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        Condition.evaluate(inputs.base)
        ? TrueModifier._makeViewList(modifier: modifier[\.trueModifier], inputs: inputs, body: body)
        : FalseModifier._makeViewList(modifier: modifier[\.falseModifier], inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        Condition.evaluate(inputs.base)
        ? TrueModifier._viewListCount(inputs: inputs, body: body)
        : FalseModifier._viewListCount(inputs: inputs, body: body)
    }
}

extension ViewInputConditionalModifier where FalseModifier == EmptyModifier {
    public init(
        _ : Condition.Type = Condition.self,
        then: TrueModifier
    ) {
        self.init(Condition.self, then: then, else: EmptyModifier())
    }
}

// MARK: - Previews

struct PreviewInput: ViewInputFlag { }
struct OtherPreviewInput: ViewInputFlag { }

struct PreviewInputRemoveModifier: ViewInputsModifier {
    static func makeInputs(
        modifier: _GraphValue<Self>,
        inputs: inout _GraphInputs
    ) {
        inputs[PreviewInput.self] = nil
    }
}

struct ViewInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ViewInputConditionalContent(PreviewInput.self) {
                Text("TRUE")
            } else: {
                Text("FALSE")
            }
            .input(PreviewInput.self)

            ViewInputConditionalContent(PreviewInput.self) {
                Text("TRUE")
            } else: {
                Text("FALSE")
            }
            .modifier(PreviewInputRemoveModifier())
            .input(PreviewInput.self)

            ViewInputConditionalContent(PreviewInput.self) {
                Text("TRUE")
            } else: {
                Text("FALSE")
            }
            .modifier(PreviewInputRemoveModifier())
            .input(OtherPreviewInput.self)
            .input(PreviewInput.self)
        }
    }
}
