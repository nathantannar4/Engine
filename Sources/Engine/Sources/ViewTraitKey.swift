//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A protocol that describes a `_ViewTraitKey` allowing for internal SwiftUI traits
/// that are `@usableFromInline` to be read and written.
///
/// For examples, see:
///  - ``ZIndexTrait``
///  - ``LayoutPriorityTrait``
///  - ``TagTrait``
///
/// See Also:
///  - ``ViewTraitWritingModifier``
///  
public protocol ViewTraitKey {
    associatedtype Value
    static var conformance: ProtocolConformance<ViewTraitKeyProtocolDescriptor>? { get }
}

public struct ZIndexTrait: ViewTraitKey {
    public typealias Value = Double
    public static let conformance = ViewTraitKeyProtocolDescriptor.conformance(
        of: "7SwiftUI14ZIndexTraitKeyV"
    )
}

public struct LayoutPriorityTrait: ViewTraitKey {
    public typealias Value = Double
    public static let conformance = ViewTraitKeyProtocolDescriptor.conformance(
        of: "7SwiftUI22LayoutPriorityTraitKeyV"
    )
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TagValueTrait<V>: ViewTraitKey {
    public enum Value {
        case untagged
        case tagged(V)
    }
    public static var conformance: ProtocolConformance<ViewTraitKeyProtocolDescriptor>? {
        guard let typeName = _mangledTypeName(V.self) else { return nil }
        return ViewTraitKeyProtocolDescriptor.conformance(
            of: "7SwiftUI16TagValueTraitKeyVy\(typeName)G"
        )
    }
}

public struct IsSectionHeaderTrait: ViewTraitKey {
    public typealias Value = Bool
    public static let conformance = ViewTraitKeyProtocolDescriptor.conformance(
        of: "7SwiftUI23IsSectionHeaderTraitKeyV"
    )
}

public struct IsSectionFooterTrait: ViewTraitKey {
    public typealias Value = Bool
    public static let conformance = ViewTraitKeyProtocolDescriptor.conformance(
        of: "7SwiftUI23IsSectionFooterTraitKeyV"
    )
}

extension AnyVariadicView.Subview {
    public subscript<K: ViewTraitKey>(
        key: K.Type
    ) -> K.Value? {
        if let conformance = K.conformance {
            var visitor = Visitor<K>(subview: self)
            conformance.visit(visitor: &visitor)
            if let value = visitor.output {
                return value
            }
        }
        return nil
    }

    private struct Visitor<K: ViewTraitKey>: ViewTraitKeyVisitor {
        var subview: AnyVariadicView.Subview
        var output: K.Value!

        mutating func visit<Key: _ViewTraitKey>(type: Key.Type) {
            if K.Value.self == Key.Value.self {
                output = subview.element[Key.self] as? K.Value
            } else if MemoryLayout<K.Value>.size == MemoryLayout<Key.Value>.size {
                output = unsafeBitCast(subview.element[Key.self], to: K.Value.self)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Layout.Subviews.Element {
    
    /// The z-index of the subview.
    public var zIndex: Double {
        self[ZIndexTrait.self, default: 0]
    }

    public subscript<K: ViewTraitKey>(
        key: K.Type
    ) -> K.Value? {
        if let conformance = K.conformance {
            var visitor = Visitor<K>(subview: self)
            conformance.visit(visitor: &visitor)
            if let value = visitor.output {
                return value
            }
        }
        return nil
    }

    public subscript<K: ViewTraitKey>(
        key: K.Type,
        default defaultValue: @autoclosure () -> K.Value
    ) -> K.Value {
        return self[K.self] ?? defaultValue()
    }

    private struct Visitor<K: ViewTraitKey>: ViewTraitKeyVisitor {
        var subview: Layout.Subviews.Element
        var output: K.Value!

        mutating func visit<Key: _ViewTraitKey>(type: Key.Type) {
            if K.Value.self == Key.Value.self {
                output = subview._trait(key: Key.self) as? K.Value
            } else if MemoryLayout<K.Value>.size == MemoryLayout<Key.Value>.size {
                output = unsafeBitCast(subview._trait(key: Key.self), to: K.Value.self)
            }
        }
    }
}

extension View {
    @inlinable
    public func trait<K: ViewTraitKey>(
        _ key: K.Type,
        _ value: K.Value
    ) -> some View {
        modifier(ViewTraitWritingModifier<K>(value: value))
    }
}

@frozen
public struct ViewTraitWritingModifier<Trait: ViewTraitKey>: ViewModifier {

    public var value: Trait.Value

    public init(value: Trait.Value) {
        self.value = value
    }

    public func body(content: Content) -> some View {
        StaticConditionalContent(ViewTraitKeyIsValid.self) {
            BodyModifier(content: content, value: value)
        } otherwise: {
            content
        }
    }

    private struct ViewTraitKeyIsValid: StaticCondition {
        static var value: Bool {
            if let conformance = Trait.conformance {
                var visitor = Visitor()
                conformance.visit(visitor: &visitor)
                return visitor.output
            }
            return false
        }

        private struct Visitor: ViewTraitKeyVisitor {
            var output: Bool!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                output = Trait.Value.self == Key.Value.self || MemoryLayout<Trait.Value>.size == MemoryLayout<Key.Value>.size
            }
        }
    }

    private struct BodyModifier: PrimitiveView {
        var content: Content
        var value: Trait.Value

        private struct TraitVisitor: ViewTraitKeyVisitor {
            var content: Content
            var value: Trait.Value
            var output: Any!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                if Trait.Value.self == Key.Value.self {
                    output = content.modifier(
                        _TraitWritingModifier<Key>(value: value as! Key.Value)
                    )
                } else if MemoryLayout<Trait.Value>.size == MemoryLayout<Key.Value>.size {
                    output = content.modifier(
                        _TraitWritingModifier<Key>(value: unsafeBitCast(value, to: Key.Value.self))
                    )
                }
            }
        }

        private var modifiedContent: Any {
            let conformance = Trait.conformance!
            var visitor = TraitVisitor(
                content: content,
                value: value
            )
            conformance.visit(visitor: &visitor)
            return visitor.output!
        }

        static func makeView(
            view: _GraphValue<Self>,
            inputs: _ViewInputs
        ) -> _ViewOutputs {
            let conformance = Trait.conformance!
            var visitor = ViewOutputsVisitor(
                view: view[\.modifiedContent],
                inputs: inputs
            )
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }

        static func makeViewList(
            view: _GraphValue<Self>,
            inputs: _ViewListInputs
        ) -> _ViewListOutputs {
            let conformance = Trait.conformance!
            var visitor = ViewListOutputsVisitor(
                view: view[\.modifiedContent],
                inputs: inputs
            )
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        static func viewListCount(
            inputs: _ViewListCountInputs
        ) -> Int? {
            let conformance = Trait.conformance!
            var visitor = ViewListCountVisitor(
                inputs: inputs
            )
            conformance.visit(visitor: &visitor)
            return visitor.outputs
        }

        private struct ViewOutputsVisitor: ViewTraitKeyVisitor {
            var view: _GraphValue<Any>
            var inputs: _ViewInputs
            var outputs: _ViewOutputs!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                let view = unsafeBitCast(
                    view,
                    to: _GraphValue<ModifiedContent<Content, _TraitWritingModifier<Key>>>.self
                )
                outputs = ModifiedContent<Content, _TraitWritingModifier<Key>>._makeView(
                    view: view,
                    inputs: inputs
                )
            }
        }

        private struct ViewListOutputsVisitor: ViewTraitKeyVisitor {
            var view: _GraphValue<Any>
            var inputs: _ViewListInputs
            var outputs: _ViewListOutputs!

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                let view = unsafeBitCast(
                    view,
                    to: _GraphValue<ModifiedContent<Content, _TraitWritingModifier<Key>>>.self
                )
                outputs = ModifiedContent<Content, _TraitWritingModifier<Key>>._makeViewList(
                    view: view,
                    inputs: inputs
                )
            }
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        private struct ViewListCountVisitor: ViewTraitKeyVisitor {
            var inputs: _ViewListCountInputs
            var outputs: Int?

            mutating func visit<Key>(type: Key.Type) where Key: _ViewTraitKey {
                outputs = ModifiedContent<Content, _TraitWritingModifier<Key>>._viewListCount(
                    inputs: inputs
                )
            }
        }
    }
}

struct ViewTraitKey_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack {
                ZStack {
                    Color.red
                        .frame(height: 100)
                        .trait(ZIndexTrait.self, 1)

                    Color.blue
                        .frame(height: 200)
                }

                ZStack {
                    Color.red
                        .frame(height: 100)
                        .zIndex(1)

                    Color.blue
                        .frame(height: 200)
                }
            }
            .previewDisplayName("ZIndexTrait")

            HStack {
                HStack {
                    Color.blue
                        .trait(LayoutPriorityTrait.self, 1)

                    Color.red
                }

                HStack {
                    Color.blue
                        .layoutPriority(1)

                    Color.red
                }
            }
            .previewDisplayName("LayoutPriorityTrait")

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                HStack {
                    VariadicViewAdapter {
                        Color.blue
                            .trait(TagValueTrait<String>.self, .tagged("Hello, World"))
                    } content: { source in
                        Text(source[0].tag(as: String.self) ?? "nil")
                    }

                }
                .previewDisplayName("TagValueTrait")
            }
        }
    }
}
