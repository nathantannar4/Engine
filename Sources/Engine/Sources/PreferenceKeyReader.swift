//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A proxy to a `Key.Value` that must be read by ``PreferenceKeyValueReader``
@frozen
public struct PreferenceKeyValueProxy<Key: PreferenceKey> {
    var value: _PreferenceValue<Key>
}

/// A container view that resolves it's content from a preference key
@frozen
public struct PreferenceKeyReader<
    Key: PreferenceKey,
    Content: View
>: View {

    public typealias Value = PreferenceKeyValueProxy<Key>

    @usableFromInline
    var content: (Value) -> Content

    @inlinable
    public init(
        _ key: Key.Type,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.content = content
    }

    public var body: some View {
        Key._delay { value in
            content(PreferenceKeyValueProxy(value: value))
        }
    }
}

/// A container view that resolves it's content from a preference key value
///
/// > Important: The preference key value of `Content` is ignored
@frozen
public struct PreferenceKeyValueReader<
    Key: PreferenceKey,
    Content: View
>: View {

    @usableFromInline
    var value: PreferenceKeyValueProxy<Key>

    @usableFromInline
    var content: (Key.Value) -> Content

    @inlinable
    public init(
        value: PreferenceKeyValueProxy<Key>,
        @ViewBuilder content: @escaping (Key.Value) -> Content
    ) {
        self.value = value
        self.content = content
    }

    public var body: some View {
        _PreferenceReadingView(value: value.value) { value in
            content(value)
        }
    }
}

// MARK: - Previews

struct PreferenceKeyReader_Previews: PreviewProvider {
    struct TestKey: PreferenceKey {
        static let defaultValue = "default"

        static func reduce(value: inout String, nextValue: () -> String) { }
    }

    static var previews: some View {
        VStack {
            PreferenceKeyReader(TestKey.self) { value in
                VStack {
                    Text("Label")
                        .preference(key: TestKey.self, value: "Hello, World")

                    PreferenceKeyValueReader(value: value) { value in
                        Text(value)
                    }
                }
            }
        }
    }
}
