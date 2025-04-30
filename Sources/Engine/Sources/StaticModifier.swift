//
// Copyright (c) Nathan Tannar
//

import SwiftUI

import EngineCore

/// A static type-erased `ViewModifier`.
///
/// > Warning: The ``TypeDescriptor/descriptor`` should match the type
///  returned by `modifier`
@frozen
public struct StaticModifier<
    Descriptor: TypeDescriptor
>: PrimitiveViewModifier {

    @usableFromInline
    var modifier: Any

    @inlinable
    public init(
        _ descriptor: Descriptor.Type = Descriptor.self,
        modifier: () -> Any
    ) {
        self.modifier = modifier()
    }

    public static func makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        func project<T>(_ type: T.Type) -> _ViewOutputs {
            let conformance = ViewModifierProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewOutputsVisitor(view: modifier[\.modifier], inputs: inputs, body: body)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }

    public static func makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        func project<T>(_ type: T.Type) -> _ViewListOutputs {
            let conformance = ViewModifierProtocolDescriptor.conformance(of: T.self)!
            var visitor = ViewListOutputsVisitor(view: modifier[\.modifier], inputs: inputs, body: body)
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        func project<T>(_ type: T.Type) -> Int? {
            withoutActuallyEscaping(body) { body in
                let conformance = ViewModifierProtocolDescriptor.conformance(of: T.self)!
                var visitor = ViewListOutputsCountVisitor(inputs: inputs, body: body)
                conformance.visit(visitor: &visitor)
                return visitor.outputs
            }
        }
        let type = unsafeBitCast(Descriptor.descriptor, to: Any.Type.self)
        return _openExistential(type, do: project)
    }
}

private struct StaticModifierBody<Modifier: ViewModifier>: ViewModifier {
    var modifier: Any

    func body(content: Content) -> some View {
        content.modifier(modifier as! Modifier)
    }
}

private struct ViewOutputsVisitor: ViewModifierVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewInputs
    var body: (_Graph, _ViewInputs) -> _ViewOutputs

    var outputs: _ViewOutputs!

    mutating func visit<Modifier>(type: Modifier.Type) where Modifier: ViewModifier {
        let modifier = unsafeBitCast(view, to: _GraphValue<StaticModifierBody<Modifier>>.self)
        outputs = StaticModifierBody<Modifier>._makeView(modifier: modifier, inputs: inputs, body: body)
    }
}

private struct ViewListOutputsVisitor: ViewModifierVisitor {
    var view: _GraphValue<Any>
    var inputs: _ViewListInputs
    var body: (_Graph, _ViewListInputs) -> _ViewListOutputs

    var outputs: _ViewListOutputs!

    mutating func visit<Modifier>(type: Modifier.Type) where Modifier: ViewModifier {
        let modifier = unsafeBitCast(view, to: _GraphValue<StaticModifierBody<Modifier>>.self)
        outputs = StaticModifierBody<Modifier>._makeViewList(modifier: modifier, inputs: inputs, body: body)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct ViewListOutputsCountVisitor: ViewModifierVisitor {
    var inputs: _ViewListCountInputs
    var body: (_ViewListCountInputs) -> Int?

    var outputs: Int?

    mutating func visit<Modifier>(type: Modifier.Type) where Modifier: ViewModifier {
        outputs = StaticModifierBody<Modifier>._viewListCount(inputs: inputs, body: body)
    }
}

// MARK: - Previews

struct StaticModifier_Previews: PreviewProvider {

    struct Modifier: ViewModifier {
        func body(content: Content) -> some View {
            content.border(Color.red)
        }
    }

    struct Descriptor: TypeDescriptor {
        static var descriptor: UnsafeRawPointer {
            TypeIdentifier(Modifier.self).metadata
        }
    }

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier {
                    StaticModifier<Descriptor> {
                        Modifier()
                    }
                }
        }
    }
}
