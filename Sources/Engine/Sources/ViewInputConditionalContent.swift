//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A `View` that is statically either `TrueContent` or `FalseContent`.
@frozen
public struct ViewInputConditionalContent<
    Condition: ViewInputsCondition,
    TrueContent: View,
    FalseContent: View
>: PrimitiveView {

    @usableFromInline
    nonisolated(unsafe) var trueContent: TrueContent

    @usableFromInline
    nonisolated(unsafe) var falseContent: FalseContent

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder otherwise: () -> FalseContent
    ) {
        self.trueContent = then()
        self.falseContent = otherwise()
    }

    @inlinable
    public init(
        _ : Condition,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder otherwise: () -> FalseContent
    ) {
        self.trueContent = then()
        self.falseContent = otherwise()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        Condition.evaluate(ViewInputs(inputs: inputs))
            ? TrueContent._makeView(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeView(view: view[\.falseContent], inputs: inputs)
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        Condition.evaluate(ViewInputs(inputs: inputs))
            ? TrueContent._makeViewList(view: view[\.trueContent], inputs: inputs)
            : FalseContent._makeViewList(view: view[\.falseContent], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        Condition.evaluate(ViewInputs(inputs: inputs))
            ? TrueContent._viewListCount(inputs: inputs)
            : FalseContent._viewListCount(inputs: inputs)
    }
}

extension ViewInputConditionalContent where FalseContent == EmptyView {
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(Condition.self, then: then, otherwise: { EmptyView() })
    }

    public init(
        _ : Condition,
        @ViewBuilder then: () -> TrueContent
    ) {
        self.init(Condition.self, then: then, otherwise: { EmptyView() })
    }
}

// MARK: - Previews

struct ViewInputConditionalContent_Previews: PreviewProvider {
    struct PreviewFlag: ViewInputFlag { }

    struct Preview: View {
        var label: String
        @State var value = 0

        var body: some View {
            Button {
                value += 1
            } label: {
                Text(verbatim: "\(label) \(value.description)")
            }
        }
    }

    static var previews: some View {
        VStack {
            ViewInputConditionalContent(PreviewFlag.self) {
                Preview(label: "TRUE")
            } otherwise: {
                Preview(label: "FALSE")
            }
            .input(PreviewFlag.self)

            ViewInputConditionalContent(PreviewFlag.self) {
                Preview(label: "TRUE")
            } otherwise: {
                Preview(label: "FALSE")
            }
        }
    }
}
