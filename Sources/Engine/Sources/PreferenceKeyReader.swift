//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A proxy to a `PreferenceKey.Value` that must be read by ``PreferenceKeyValueReader``
@frozen
public struct PreferenceKeyValueProxy<Key: PreferenceKey> {
    var value: _PreferenceValue<Key>
}

/// A container view that resolves it's content from a `PreferenceKey`
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
            content(Value(value: value))
        }
    }
}

/// A container view that resolves it's content from a `PreferenceKey` value
///
/// > Important: The `PreferenceKey` value of `Content` is ignored
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
        _ value: PreferenceKeyValueProxy<Key>,
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
    struct PreviewPreferenceKey: PreferenceKey {
        static let defaultValue = "default"

        static func reduce(
            value: inout String,
            nextValue: () -> String
        ) { }
    }

    static var previews: some View {
        Group {
            ZStack {
                PreferenceKeyReader(PreviewPreferenceKey.self) { proxy in
                    VStack {
                        Text("Label")
                            .preference(
                                key: PreviewPreferenceKey.self,
                                value: "Hello, World"
                            )

                        PreferenceKeyValueReader(proxy) { value in
                            Text(value) // "Hello, World"
                        }
                    }
                }
            }
            .previewDisplayName("Correct Usage")

            ZStack {
                PreferenceKeyReader(PreviewPreferenceKey.self) { proxy in
                    PreferenceKeyValueReader(proxy) { value in
                        Text(value) // "default"
                            .preference(
                                key: PreviewPreferenceKey.self,
                                value: "Hello, World"
                            )
                    }
                }
            }
            .previewDisplayName("Incorrect Usage")
        }
    }
}
