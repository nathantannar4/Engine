//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A wrapper for `@ViewBuilder`
@frozen
public struct ViewAdapter<Content: View>: PrimitiveView {

    @usableFromInline
    var content: Content

    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private nonisolated var _body: ViewAdapterBody<Content> {
        ViewAdapterBody(content: self)
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        ViewAdapterBody<Content>._makeView(view: view[\._body], inputs: inputs)
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        ViewAdapterBody<Content>._makeViewList(view: view[\._body], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        ViewAdapterBody<Content>._viewListCount(inputs: inputs)
    }
}

private struct ViewAdapterBody<Content: View>: View {
    nonisolated(unsafe) var content: ViewAdapter<Content>

    var body: some View {
        content.content
    }
}

// MARK: - Previews

struct ViewAdapter_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        var body: some View {
            ViewAdapter {
                Content()
            }
        }

        struct Content: View {
            @State var value = 0

            var body: some View {
                Button(value.description) {
                    value += 1
                }
            }
        }
    }
}
