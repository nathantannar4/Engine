//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that displays a ``VersionedView`` when it has a body for the
/// current version, otherwise displays the `unavailable` content.
///
/// A version is considered unavailable when the body of the ``VersionedView``
/// resolves to `EmptyView`, which is the default for versions that have not
/// been implemented.
///
@frozen
public struct VersionedViewAdapter<
    Content: VersionedView,
    UnavailableContent: View
>: PrimitiveView {

    @usableFromInline
    nonisolated(unsafe) var content: Content

    @usableFromInline
    nonisolated(unsafe) var unavailableContent: UnavailableContent

    @inlinable
    public init(
        content: Content,
        @ViewBuilder unavailable: () -> UnavailableContent
    ) {
        self.init(content: content, unavailable: unavailable())
    }

    @inlinable
    public init(
        content: Content,
        unavailable: UnavailableContent = EmptyView()
    ) {
        self.content = content
        self.unavailableContent = unavailable
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Content.self)
        return isAvailable
            ? Content._makeView(view: view[\.content], inputs: inputs)
            : UnavailableContent._makeView(view: view[\.unavailableContent], inputs: inputs)
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Content.self)
        return isAvailable
            ? Content._makeViewList(view: view[\.content], inputs: inputs)
            : UnavailableContent._makeViewList(view: view[\.unavailableContent], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        let isAvailable = version.isAvailable(Content.self)
        return isAvailable
            ? Content._viewListCount(inputs: inputs)
            : UnavailableContent._viewListCount(inputs: inputs)
    }
}

// MARK: - Previews

struct VersionedViewAdapter_Previews: PreviewProvider {
    struct PreviewVersionedView: VersionedView {
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        var v3Body: some View { Text("V3+") }
    }

    static var previews: some View {
        VStack {
            VersionedViewAdapter(content: PreviewVersionedView()) {
                Text("Unavailable")
            }

            VersionedViewAdapter(content: PreviewVersionedView()) {
                Text("Unavailable")
            }
            .version(.v3)

            VersionedViewAdapter(content: PreviewVersionedView()) {
                Text("Unavailable")
            }
            .version(.v2)
        }
        .padding()
    }
}
