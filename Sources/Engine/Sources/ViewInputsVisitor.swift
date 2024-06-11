//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``ViewInputsVisitor`` allows for the custom view inputs of `_GraphInputs`
/// to be iterated upon
public protocol ViewInputsVisitor {

    func visit<Value>(_ value: Value, key: String, stop: inout Bool)
}

extension _GraphInputs {

    /// Visits the custom view inputs with the `Visitor`
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        var ptr = customInputs.elements
        var stop = false
        while !stop, let p = ptr {
            let next = p.after
            defer { ptr = next }
            stop = next == nil
            let key = _typeName(p.keyType, qualified: false)
            let value: Any.Type
            if let inputKey = p.keyType as? AnyViewInputKey.Type {
                value = inputKey.value
            } else {
                guard let valueType = swift_getClassGenerics(for: p.metadata.0)?.first
                else {
                    continue
                }
                print(p.keyType, p.metadata.0, valueType)
                value = valueType
            }
            func project<Value>(_: Value.Type) {
                let value = p.getValue(Value.self)
                visitor.visit(value, key: key, stop: &stop)
            }
            _openExistential(value, do: project)
        }
    }
}

extension _ViewInputs {

    /// Visits the custom view inputs with the `Visitor`
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        _graphInputs.visit(visitor: &visitor)
    }
}

extension _ViewListInputs {

    /// Visits the custom view inputs with the `Visitor`
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        _graphInputs.visit(visitor: &visitor)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs {

    /// Visits the custom view inputs with the `Visitor`
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        _graphInputs.visit(visitor: &visitor)
    }
}

extension ViewInputs {

    /// Visits the custom view inputs with the `Visitor`
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        _graphInputs.visit(visitor: &visitor)
    }
}

public protocol ViewInputsVisitorModifier: ViewInputsModifier {
    associatedtype Visitor: ViewInputsVisitor
    static var visitor: Visitor { get }
}

extension ViewInputsVisitorModifier {
    public static func makeInputs(inputs: inout ViewInputs) {
        var visitor = visitor
        inputs.visit(visitor: &visitor)
    }
}

// MARK: - Previews

struct ViewInputsVisitor_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(VisitorModifier())
                .buttonStyle(.plain)
        }
    }

    struct VisitorModifier: ViewInputsVisitorModifier {
        static var visitor: Visitor {
            Visitor()
        }
    }

    struct Visitor: ViewInputsVisitor {
        func visit<Value>(_ value: Value, key: String, stop: inout Bool) {
            print(key, value)
        }
    }
}
