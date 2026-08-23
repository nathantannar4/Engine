//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that writes a `PreferenceKey`
@frozen
public struct PreferenceKeyWritingModifier<
    Key: PreferenceKey
>: ViewModifier {

    @usableFromInline
    var value: Key.Value

    @inlinable
    public init(
        _ key: Key.Type = Key.self,
        value: Key.Value
    ) {
        self.value = value
    }

    public func body(content: Content) -> some View {
        content
            .preference(key: Key.self, value: value)
    }
}
