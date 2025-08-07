//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A value thats readable by a ``AnyVariadicView/Subview`` or a `Layout.Subviews.Element`
///
/// A ``TraitValueKey`` is only readable by the views direct parent, such as the custom layout
/// or `VStack`/`HStack`/`ZStack` that it is contained within.
///
/// > Note: Similar to `LayoutValueTrait` but backwards compatible to work with any
/// view when transformed with a ``VariadicViewAdapter``
///
public protocol TraitValueKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
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
}

extension AnyVariadicView.Subview {
    public subscript<Key: TraitValueKey>(
        key: Key.Type
    ) -> Key.Value {
        get { self[TraitValueKeyBox<Key>.self] }
        set { self[TraitValueKeyBox<Key>.self] = newValue }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Layout.Subviews.Element {
    public subscript<Key: TraitValueKey>(
        key: Key.Type
    ) -> Key.Value {
        _trait(key: TraitValueKeyBox<Key>.self)
    }
}

private struct TraitValueKeyBox<Key: TraitValueKey>: _ViewTraitKey {
    typealias Value = Key.Value
    static var defaultValue: Key.Value { Key.defaultValue }
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
                let sortedChildren = content.children
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
