//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A value thats readable by a ``AnyVariadicView/Subview``
/// or a `Layout.Subviews.Element`
public protocol TraitValueKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
}

private struct TraitValueKeyBox<Key: TraitValueKey>: _ViewTraitKey {
    typealias Value = Key.Value
    static var defaultValue: Key.Value { Key.defaultValue }
}

extension View {
    public func trait<K: TraitValueKey>(
        _ key: K.Type,
        _ value: K.Value
    ) -> some View {
        modifier(_TraitWritingModifier<TraitValueKeyBox<K>>(value: value))
    }
}

extension AnyVariadicView.Subview {
    public subscript<K: TraitValueKey>(key: K.Type) -> K.Value {
        get { self[TraitValueKeyBox<K>.self] }
        set { self[TraitValueKeyBox<K>.self] = newValue }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Layout.Subviews.Element {
    public subscript<K: TraitValueKey>(key: K.Type) -> K.Value {
        _trait(key: TraitValueKeyBox<K>.self)
    }
}
