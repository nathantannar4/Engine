//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A value that's readable by a ``VariadicView/Subview`` or a `Layout.Subviews.Element`
///
/// A ``TraitValueKey`` is only readable by the view's direct parent, such as the custom layout
/// or `VStack`/`HStack`/`ZStack` that it is contained within.
///
/// > Note: Similar to `LayoutValueTrait` but backwards compatible to work with any
/// view when transformed with a ``VariadicViewAdapter``
///
public protocol TraitValueKey: ViewTraitKey {
    /// The type of value of the trait.
    associatedtype Value
    /// The default value of the trait when it has not been written to a view.
    static var defaultValue: Self.Value { get }
}

extension TraitValueKey {

    /// The `_ViewTraitKey` conformance of the private trait key that stores the value of this key.
    public static var conformance: ProtocolConformance<ViewTraitKeyProtocolDescriptor>? {
        ViewTraitKeyProtocolDescriptor.conformance(
            of: TraitValueKeyBox<Self>.self
        )
    }
}

extension View {

    /// Writes the trait `Key` to the view
    public func trait<Key: TraitValueKey>(
        _ key: Key.Type,
        _ value: Key.Value
    ) -> some View {
        modifier(
            _TraitWritingModifier<TraitValueKeyBox<Key>>(
                value: value
            )
        )
    }

    /// Conditionally writes the trait `Key` to the view
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    public func trait<Key: TraitValueKey>(
        _ key: Key.Type,
        _ value: Key.Value,
        isEnabled: Bool
    ) -> some View {
        modifier(
            _ConditionalTraitWritingModifier<TraitValueKeyBox<Key>>(
                value: value,
                isEnabled: isEnabled
            )
        )
    }
}

extension VariadicView.Subview {

    /// Accesses the value of the trait `key` for the subview.
    public subscript<K: TraitValueKey>(
        key: K.Type
    ) -> K.Value {
        get { self[TraitValueKeyBox<K>.self] }
        set { self[TraitValueKeyBox<K>.self] = newValue }
    }

    /// Returns the value of the trait `key` for the subview.
    public func trait<K: TraitValueKey>(
        _ key: K.Type
    ) -> K.Value {
        self[TraitValueKeyBox<K>.self]
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Layout.Subviews.Element {
    
    /// Returns the value of the trait `key` for the subview.
    public subscript<K: TraitValueKey>(
        key: K.Type
    ) -> K.Value {
        _trait(key: TraitValueKeyBox<K>.self)
    }

    /// Returns the value of the trait `key` for the subview.
    public func trait<K: TraitValueKey>(
        _ key: K.Type
    ) -> K.Value {
        _trait(key: TraitValueKeyBox<K>.self)
    }
}

private struct TraitValueKeyBox<K: TraitValueKey>: _ViewTraitKey {
    typealias Value = K.Value
    static var defaultValue: K.Value { K.defaultValue }
}

// MARK: - Previews

struct TraitValueKey_Previews: PreviewProvider {
    struct PreviewTraitValueKey: TraitValueKey {
        static let defaultValue: Int = 0
    }

    static var previews: some View {
        ZStack {
            VariadicViewAdapter {
                Text("Line 2")
                    .trait(PreviewTraitValueKey.self, 2)
                Text("Line 1")
                    .trait(PreviewTraitValueKey.self, 1)
            } content: { content in
                let sortedChildren = content
                    .sorted { lhs, rhs in
                        lhs[PreviewTraitValueKey.self] < rhs[PreviewTraitValueKey.self]
                    }
                VStack {
                    ForEach(sortedChildren) { subview in
                        subview
                    }
                }
            }
        }
    }
}
