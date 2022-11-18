//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A value thats readable by a ``AnyVariadicView/Subview``
/// or a `Layout.Subviews.Element`
public protocol VariadicValueKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
}

private struct VariadicValueKeyBox<Key: VariadicValueKey>: _ViewTraitKey {
    typealias Value = Key.Value
    static var defaultValue: Key.Value { Key.defaultValue }
}

extension View {
    public func variadicValue<K: VariadicValueKey>(
        _ key: K.Type,
        _ value: K.Value
    ) -> some View {
        modifier(_TraitWritingModifier<VariadicValueKeyBox<K>>(value: value))
    }
}

extension AnyVariadicView.Subview {
    public subscript<K: VariadicValueKey>(key: K.Type) -> K.Value {
        get { element[VariadicValueKeyBox<K>.self] }
        set { element[VariadicValueKeyBox<K>.self] = newValue }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Layout.Subviews.Element {
    public subscript<K: VariadicValueKey>(key: K.Type) -> K.Value {
        _trait(key: VariadicValueKeyBox<K>.self)
    }
}
