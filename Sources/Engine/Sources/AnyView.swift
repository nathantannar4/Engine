//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

extension AnyView {

    /// Creates a type-erased view from a type-erased value if that value is also a view
    public init?(_ content: Any) {
        func project<T>(_ value: T) -> AnyView? {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = AnyViewVisitor(input: value)
            conformance.visit(visitor: &visitor)
            return visitor.output
        }
        guard let view = _openExistential(content, do: project) else {
            return nil
        }
        self = view
    }
}

private struct AnyViewVisitor<Input>: ViewVisitor {
    var input: Input
    var output: AnyView!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        output = AnyView(unsafeBitCast(input, to: Content.self))
    }
}
