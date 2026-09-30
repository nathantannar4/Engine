//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A toolbar content whose `Body` is statically conditional on version availability.
///
/// Because the toolbar content is statically conditional, type erasure is
/// not needed. This is unlike `@ToolbarContentBuilder` which requires an
/// `if #available(...)` conditional to produce types that are available
/// on all versions.
///
/// By default, unsupported versions will resolve to ``EmptyToolbarContent``.
/// Supported versions that don't have their body implemented will resolve
/// to the next version body that is implemented.
///
/// > Tip: Use ``VersionedToolbarContent``, ``VersionedView`` and
/// ``VersionedViewModifier`` to aid with backwards compatibility.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol VersionedToolbarContent: ToolbarContent {

    /// The type of toolbar content representing the body on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    associatedtype V8_1Body: ToolbarContent = V8Body

    /// The content and behavior of the toolbar content on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    ///
    /// Defaults to ``v8Body``.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v8_1Body: V8_1Body { get }

    /// The type of toolbar content representing the body on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    associatedtype V8Body: ToolbarContent = V7Body

    /// The content and behavior of the toolbar content on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    ///
    /// Defaults to ``v7Body``.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v8Body: V8Body { get }

    /// The type of toolbar content representing the body on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    associatedtype V7Body: ToolbarContent = V6Body

    /// The content and behavior of the toolbar content on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    ///
    /// Defaults to ``v6Body``.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v7Body: V7Body { get }

    /// The type of toolbar content representing the body on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    associatedtype V6Body: ToolbarContent = V5Body

    /// The content and behavior of the toolbar content on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    ///
    /// Defaults to ``v5Body``.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v6Body: V6Body { get }

    /// The type of toolbar content representing the body on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    associatedtype V5Body: ToolbarContent = V4Body

    /// The content and behavior of the toolbar content on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    ///
    /// Defaults to ``v4Body``.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v5Body: V5Body { get }

    /// The type of toolbar content representing the body on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    associatedtype V4Body: ToolbarContent = V3Body

    /// The content and behavior of the toolbar content on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    ///
    /// Defaults to ``v3Body``.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v4Body: V4Body { get }

    /// The type of toolbar content representing the body on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    associatedtype V3Body: ToolbarContent = V2Body

    /// The content and behavior of the toolbar content on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    ///
    /// Defaults to ``v2Body``.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ToolbarContentBuilder @MainActor @preconcurrency var v3Body: V3Body { get }

    /// The type of toolbar content representing the body on the minimum supported OS versions,
    /// iOS 14, macOS 11, tvOS 14 and watchOS 7.
    associatedtype V2Body: ToolbarContent = EmptyToolbarContent

    /// The content and behavior of the toolbar content on the minimum supported OS versions,
    /// iOS 14, macOS 11, tvOS 14 and watchOS 7.
    ///
    /// Defaults to ``EmptyToolbarContent``.
    @ToolbarContentBuilder @MainActor @preconcurrency var v2Body: V2Body { get }
}

@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
extension VersionedToolbarContent where V8_1Body == V8Body {
    public var v8_1Body: V8Body { v8Body }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
extension VersionedToolbarContent where V8Body == V7Body {
    public var v8Body: V7Body { v7Body }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension VersionedToolbarContent where V7Body == V6Body {
    public var v7Body: V6Body { v6Body }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension VersionedToolbarContent where V6Body == V5Body {
    public var v6Body: V6Body { v5Body }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension VersionedToolbarContent where V5Body == V4Body {
    public var v5Body: V5Body { v4Body }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VersionedToolbarContent where V4Body == V3Body {
    public var v4Body: V4Body { v3Body }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VersionedToolbarContent where V3Body == V2Body {
    public var v3Body: V3Body { v2Body }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension VersionedToolbarContent where V2Body == EmptyToolbarContent {
    public var v2Body: V2Body { EmptyToolbarContent() }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension VersionedToolbarContent where Body == _VersionedToolbarContentBody<Self> {

    public var body: _VersionedToolbarContentBody<Self> {
        _VersionedToolbarContentBody(content: self)
    }
}

/// A toolbar content that contains no items.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct EmptyToolbarContent: ToolbarContent {

    @inlinable
    public nonisolated init() { }

    public var body: Never {
        fatalError("body should not be called on \(String(describing: Self.self))")
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    private nonisolated var none: Never? { nil }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public nonisolated static func _makeToolbar(
        content: _GraphValue<Self>,
        inputs: _ToolbarInputs
    ) -> _ToolbarOutputs {
        Optional<Never>._makeToolbar(content: content[\.none], inputs: inputs)
    }

    public nonisolated static func _makeContent(
        content: _GraphValue<Self>,
        inputs: _GraphInputs,
        resolved: inout _ToolbarItemList
    ) { }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct _VersionedToolbarContentBody<Content: VersionedToolbarContent>: ToolbarContent {

    nonisolated(unsafe) var content: Content

    public var body: Never {
        fatalError("body should not be called on \(String(describing: Self.self))")
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension _VersionedToolbarContentBody {

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    private nonisolated var _v8_1Body: VersionedToolbarContentV8_1Body<Content> {
        VersionedToolbarContentV8_1Body(content: content)
    }

    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    private nonisolated var _v8Body: VersionedToolbarContentV8Body<Content> {
        VersionedToolbarContentV8Body(content: content)
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    private nonisolated var _v7Body: VersionedToolbarContentV7Body<Content> {
        VersionedToolbarContentV7Body(content: content)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private nonisolated var _v6Body: VersionedToolbarContentV6Body<Content> {
        VersionedToolbarContentV6Body(content: content)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    private nonisolated var _v5Body: VersionedToolbarContentV5Body<Content> {
        VersionedToolbarContentV5Body(content: content)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    private nonisolated var _v4Body: VersionedToolbarContentV4Body<Content> {
        VersionedToolbarContentV4Body(content: content)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private nonisolated var _v3Body: VersionedToolbarContentV3Body<Content> {
        VersionedToolbarContentV3Body(content: content)
    }

    private nonisolated var _v2Body: VersionedToolbarContentV2Body<Content> {
        VersionedToolbarContentV2Body(content: content)
    }

    typealias V0Body = EmptyToolbarContent
    nonisolated var _v0Body: V0Body {
        V0Body()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public nonisolated static func _makeToolbar(
        content: _GraphValue<Self>,
        inputs: _ToolbarInputs
    ) -> _ToolbarOutputs {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs.graphInputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        switch version {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return VersionedToolbarContentV8_1Body<Content>._makeToolbar(
                    content: content[\._v8_1Body],
                    inputs: inputs
                )
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return VersionedToolbarContentV8Body<Content>._makeToolbar(
                    content: content[\._v8Body],
                    inputs: inputs
                )
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return VersionedToolbarContentV7Body<Content>._makeToolbar(
                    content: content[\._v7Body],
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return VersionedToolbarContentV6Body<Content>._makeToolbar(
                    content: content[\._v6Body],
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return VersionedToolbarContentV5Body<Content>._makeToolbar(
                    content: content[\._v5Body],
                    inputs: inputs
                )
            }
        case .v4:
            return VersionedToolbarContentV4Body<Content>._makeToolbar(
                content: content[\._v4Body],
                inputs: inputs
            )
        case .v3:
            return VersionedToolbarContentV3Body<Content>._makeToolbar(
                content: content[\._v3Body],
                inputs: inputs
            )
        case .v2:
            return VersionedToolbarContentV2Body<Content>._makeToolbar(
                content: content[\._v2Body],
                inputs: inputs
            )
        default:
            break
        }
        return V0Body._makeToolbar(
            content: content[\._v0Body],
            inputs: inputs
        )
    }

    public nonisolated static func _makeContent(
        content: _GraphValue<Self>,
        inputs: _GraphInputs,
        resolved: inout _ToolbarItemList
    ) {
        #if DEBUG
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        #else
        let version = VersionInputKey.defaultValue
        #endif
        switch version {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return VersionedToolbarContentV8_1Body<Content>._makeContent(
                    content: content[\._v8_1Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return VersionedToolbarContentV8Body<Content>._makeContent(
                    content: content[\._v8Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return VersionedToolbarContentV7Body<Content>._makeContent(
                    content: content[\._v7Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return VersionedToolbarContentV6Body<Content>._makeContent(
                    content: content[\._v6Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return VersionedToolbarContentV5Body<Content>._makeContent(
                    content: content[\._v5Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return VersionedToolbarContentV4Body<Content>._makeContent(
                    content: content[\._v4Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return VersionedToolbarContentV3Body<Content>._makeContent(
                    content: content[\._v3Body],
                    inputs: inputs,
                    resolved: &resolved
                )
            }
        case .v2:
            return VersionedToolbarContentV2Body<Content>._makeContent(
                content: content[\._v2Body],
                inputs: inputs,
                resolved: &resolved
            )
        default:
            break
        }
        V0Body._makeContent(
            content: content[\._v0Body],
            inputs: inputs,
            resolved: &resolved
        )
    }
}

@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
private struct VersionedToolbarContentV8_1Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v8_1Body
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
private struct VersionedToolbarContentV8Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v8Body
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private struct VersionedToolbarContentV7Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v7Body
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct VersionedToolbarContentV6Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v6Body
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
private struct VersionedToolbarContentV5Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v5Body
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct VersionedToolbarContentV4Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v4Body
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct VersionedToolbarContentV3Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v3Body
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct VersionedToolbarContentV2Body<Content: VersionedToolbarContent>: ToolbarContent {
    nonisolated(unsafe) var content: Content

    var body: some ToolbarContent {
        content.v2Body
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _ToolbarInputs {

    /// The underlying graph inputs.
    public var graphInputs: _GraphInputs {
        get {
            do {
                let inputs = try swift_getFieldValue("base", _GraphInputs.self, self)
                return inputs
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
        set {
            do {
                try swift_setFieldValue("base", newValue, &self)
            } catch {
                preconditionFailure("Unexpected failure, please file a bug with error: \(error)")
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct VersionedToolbarContent_Previews: PreviewProvider {
    struct PreviewVersionedToolbarContent: VersionedToolbarContent {
        @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
        var v7Body: some ToolbarContent {
            ToolbarItem {
                Text("V7")
            }
        }

        var v2Body: some ToolbarContent {
            ToolbarItem {
                Text("V2")
            }
        }
    }

    static var previews: some View {
        VStack {
            NavigationView {
                Text("Hello, World")
                    .toolbar {
                        PreviewVersionedToolbarContent()
                    }
            }

            NavigationView {
                Text("Hello, World")
                    .toolbar {
                        PreviewVersionedToolbarContent()
                    }
                    .version(.v2)
            }
        }
    }
}
