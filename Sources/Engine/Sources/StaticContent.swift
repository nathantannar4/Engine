//
// Copyright (c) Nathan Tannar
//

import SwiftUI

import EngineCore

/// A static type-erased `View`.
///
/// > Warning: The ``TypeDescriptor/descriptor`` should match the type
///  returned by `content`
@frozen
public struct StaticContent<Descriptor: TypeDescriptor>: PrimitiveView {

    @usableFromInline
    var content: Any

    @inlinable
    public init(
        _ descriptor: Descriptor.Type = Descriptor.self,
        content: () -> Any
    ) {
        self.content = content()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        func project<T>(_ type: T.Type) -> _ViewOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewOutputsVisitor(view: view[\.content], inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        func project<T>(_ type: T.Type) -> _ViewListOutputs {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsVisitor(view: view[\.content], inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        func project<T>(_ type: T.Type) -> Int? {
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsCountVisitor(inputs: inputs)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }
}

private struct StaticContentBody<Content: View>: View {
    var content: Any

    var body: Content {
        content as! Content
    }
}

private struct ViewOutputsVisitor: ViewVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewInputs

    var outputs: _ViewOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(view, to: _GraphValue<StaticContentBody<Content>>.self)
        outputs = StaticContentBody<Content>._makeView(view: view, inputs: inputs)
    }
}

private struct ViewListOutputsVisitor: ViewVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewListInputs

    var outputs: _ViewListOutputs!

    mutating func visit<Content>(type: Content.Type) where Content: View {
        let view = unsafeBitCast(view, to: _GraphValue<StaticContentBody<Content>>.self)
        outputs = StaticContentBody<Content>._makeViewList(view: view, inputs: inputs)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewListOutputsCountVisitor: ViewVisitor {
    var inputs: _ViewListCountInputs

    var outputs: Int?

    mutating func visit<Content>(type: Content.Type) where Content: View {
        outputs = StaticContentBody<Content>._viewListCount(inputs: inputs)
    }
}

// MARK: - Previews

struct StaticContent_Previews: PreviewProvider {

    struct Content: View {
        var body: some View {
            Text("Hello, World")
        }
    }

    struct Descriptor: TypeDescriptor {
        static var descriptor: UnsafeRawPointer {
            TypeIdentifier(Content.self).metadata
        }
    }

    static var previews: some View {
        VStack {
            StaticContent<Descriptor> {
                Content()
            }
        }
    }
}
