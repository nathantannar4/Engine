//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``ViewInputsVisitor`` allows for the custom view inputs of `_GraphInputs`
/// to be iterated upon.
public protocol ViewInputsVisitor {

    /// Visits a custom view input.
    ///
    /// - Parameters:
    ///   - value: The value of the input.
    ///   - key: The fully qualified type name of the input key.
    ///   - stop: Set to `true` to stop visiting the remaining inputs.
    mutating func visit<Value>(_ value: Value, key: String, stop: inout Bool)
}

extension ViewInputs {

    /// Visits the custom view inputs with the `Visitor`.
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        var ptr = customInputs.elements
        var stop = false
        while !stop, let p = ptr {
            let next = p.advanced()
            defer { ptr = next }
            stop = next == nil
            let key = _typeName(p.keyType, qualified: true)
            visitor.visit(p.value, key: key, stop: &stop)
        }
    }
}

extension _GraphInputs {

    /// Visits the custom view inputs with the `Visitor`.
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        ViewInputs(inputs: self).visit(visitor: &visitor)
    }
}

extension _ViewInputs {

    /// Visits the custom view inputs with the `Visitor`.
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        ViewInputs(inputs: self).visit(visitor: &visitor)
    }
}

extension _ViewListInputs {

    /// Visits the custom view inputs with the `Visitor`.
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        ViewInputs(inputs: self).visit(visitor: &visitor)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _ViewListCountInputs {

    /// Visits the custom view inputs with the `Visitor`.
    public func visit<
        Visitor: ViewInputsVisitor
    >(
        visitor: inout Visitor
    ) {
        ViewInputs(inputs: self).visit(visitor: &visitor)
    }
}

/// A ``ViewInputsModifier`` that visits the custom view inputs of its content with a ``ViewInputsVisitor``.
public protocol ViewInputsVisitorModifier: ViewInputsModifier {
    /// The type of visitor.
    associatedtype Visitor: ViewInputsVisitor
    /// The visitor used to visit the custom view inputs.
    nonisolated static var visitor: Visitor { get }
}

extension ViewInputsVisitorModifier {
    public nonisolated static func makeInputs(
        inputs: inout ViewInputs
    ) {
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
            var message = "\(key)\n"
            dump(value, to: &message)
            print(message)
        }
    }
}
