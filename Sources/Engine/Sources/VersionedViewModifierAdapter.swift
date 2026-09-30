//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that applies a ``VersionedViewModifier`` when it has a body for
/// the current version, otherwise applies the `unavailable` modifier.
///
/// A version is considered unavailable when the body of the ``VersionedViewModifier``
/// resolves to `Content`, which is the default for versions that have not
/// been implemented.
///
@frozen
public struct VersionedViewModifierAdapter<
    Modifier: VersionedViewModifier,
    UnavailableModifier: ViewModifier
>: PrimitiveViewModifier {

    @usableFromInline
    nonisolated(unsafe) var modifier: Modifier

    @usableFromInline
    nonisolated(unsafe) var unavailableModifier: UnavailableModifier

    @inlinable
    public init(
        modifier: Modifier,
        @ViewModifierBuilder unavailable: () -> UnavailableModifier
    ) {
        self.init(modifier: modifier, unavailable: unavailable())
    }

    @inlinable
    public init(
        modifier: Modifier,
        unavailable: UnavailableModifier = EmptyModifier()
    ) {
        self.modifier = modifier
        self.unavailableModifier = unavailable
    }

    public nonisolated static func makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Modifier.self)
        return isAvailable
            ? Modifier._makeView(modifier: modifier[\.modifier], inputs: inputs, body: body)
            : UnavailableModifier._makeView(modifier: modifier[\.unavailableModifier], inputs: inputs, body: body)
    }

    public nonisolated static func makeViewList(
        modifier: _GraphValue<Self>,
        inputs: _ViewListInputs,
        body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs
    ) -> _ViewListOutputs {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Modifier.self)
        return isAvailable
            ? Modifier._makeViewList(modifier: modifier[\.modifier], inputs: inputs, body: body)
            : UnavailableModifier._makeViewList(modifier: modifier[\.unavailableModifier], inputs: inputs, body: body)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs,
        body: (_ViewListCountInputs) -> Int?
    ) -> Int? {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Modifier.self)
        return isAvailable
            ? Modifier._viewListCount(inputs: inputs, body: body)
            : UnavailableModifier._viewListCount(inputs: inputs, body: body)
    }
}

// MARK: - Previews

struct VersionedViewModifierAdapter_Previews: PreviewProvider {
    struct PreviewVersionedViewModifier: VersionedViewModifier {
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        func v3Body(content: Content) -> some View {
            content.border(Color.green)
        }
    }

    struct PreviewUnavailableModifier: ViewModifier {
        func body(content: Content) -> some View {
            content.border(Color.red)
        }
    }

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(
                    VersionedViewModifierAdapter(modifier: PreviewVersionedViewModifier()) {
                        PreviewUnavailableModifier()
                    }
                )

            Text("Hello, World")
                .modifier(
                    VersionedViewModifierAdapter(modifier: PreviewVersionedViewModifier()) {
                        PreviewUnavailableModifier()
                    }
                )
                .version(.v3)

            Text("Hello, World")
                .modifier(
                    VersionedViewModifierAdapter(modifier: PreviewVersionedViewModifier()) {
                        PreviewUnavailableModifier()
                    }
                )
                .version(.v2)
        }
        .padding()
    }
}
