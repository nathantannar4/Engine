//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view whose `Body` is statically conditional on version availability.
///
/// Because the view is statically conditional, `AnyView` is not needed
/// for type erasure. This is unlike `@ViewBuilder` which requires an
/// `if #available(...)` conditional to be type-erased by `AnyView`.
///
/// By default, unsupported versions will resolve to `EmptyView`. Supported
/// versions that don't have their body implemented will resolve to the next
/// version body that is implemented.
///
/// > Tip: Use ``VersionedView`` and ``VersionedViewModifier``
/// to aid with backwards compatibility.
///
public protocol VersionedView: View {

    /// The type of view representing the body on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    associatedtype V8_1Body: View = V8Body

    /// The content and behavior of the view on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    ///
    /// Defaults to ``v8Body``.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    @ViewBuilder @MainActor @preconcurrency var v8_1Body: V8_1Body { get }

    /// The type of view representing the body on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    associatedtype V8Body: View = V7Body

    /// The content and behavior of the view on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    ///
    /// Defaults to ``v7Body``.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    @ViewBuilder @MainActor @preconcurrency var v8Body: V8Body { get }

    /// The type of view representing the body on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    associatedtype V7Body: View = V6Body

    /// The content and behavior of the view on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    ///
    /// Defaults to ``v6Body``.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @ViewBuilder @MainActor @preconcurrency var v7Body: V7Body { get }

    /// The type of view representing the body on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    associatedtype V6Body: View = V5Body

    /// The content and behavior of the view on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    ///
    /// Defaults to ``v5Body``.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @ViewBuilder @MainActor @preconcurrency var v6Body: V6Body { get }

    /// The type of view representing the body on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    associatedtype V5Body: View = V4Body

    /// The content and behavior of the view on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    ///
    /// Defaults to ``v4Body``.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @ViewBuilder @MainActor @preconcurrency var v5Body: V5Body { get }

    /// The type of view representing the body on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    associatedtype V4Body: View = V3Body

    /// The content and behavior of the view on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    ///
    /// Defaults to ``v3Body``.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder @MainActor @preconcurrency var v4Body: V4Body { get }

    /// The type of view representing the body on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    associatedtype V3Body: View = V2Body

    /// The content and behavior of the view on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    ///
    /// Defaults to ``v2Body``.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder @MainActor @preconcurrency var v3Body: V3Body { get }

    /// The type of view representing the body on iOS 14, macOS 11, tvOS 14 and watchOS 7 or later.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    associatedtype V2Body: View = V1Body

    /// The content and behavior of the view on iOS 14, macOS 11, tvOS 14 and watchOS 7 or later.
    ///
    /// Defaults to ``v1Body``.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder @MainActor @preconcurrency var v2Body: V2Body { get }

    /// The type of view representing the body on the minimum supported OS versions.
    associatedtype V1Body: View = EmptyView

    /// The content and behavior of the view on the minimum supported OS versions.
    ///
    /// Defaults to `EmptyView`.
    @ViewBuilder @MainActor @preconcurrency var v1Body: V1Body { get }
}

@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
extension VersionedView where V8_1Body == V8Body {
    public var v8_1Body: V8Body { v8Body }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
extension VersionedView where V8Body == V7Body {
    public var v8Body: V7Body { v7Body }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension VersionedView where V7Body == V6Body {
    public var v7Body: V6Body { v6Body }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension VersionedView where V6Body == V5Body {
    public var v6Body: V6Body { v5Body }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension VersionedView where V5Body == V4Body {
    public var v5Body: V5Body { v4Body }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VersionedView where V4Body == V3Body {
    public var v4Body: V4Body { v3Body }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VersionedView where V3Body == V2Body {
    public var v3Body: V3Body { v2Body }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension VersionedView where V2Body == V1Body {
    public var v2Body: V2Body { v1Body }
}

extension VersionedView where V1Body == EmptyView {
    public var v1Body: V1Body { EmptyView() }
}

extension VersionedView where Body == _VersionedViewBody<Self> {

    public var body: _VersionedViewBody<Self> {
        _VersionedViewBody(content: self)
    }
}

@frozen
public struct _VersionedViewBody<Content: VersionedView>: PrimitiveView {

    nonisolated(unsafe) var content: Content
}

extension _VersionedViewBody {

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    private nonisolated var _v8_1Body: VersionedViewV8_1Body<Content> {
        VersionedViewV8_1Body(content: content)
    }

    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    private nonisolated var _v8Body: VersionedViewV8Body<Content> {
        VersionedViewV8Body(content: content)
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    private nonisolated var _v7Body: VersionedViewV7Body<Content> {
        VersionedViewV7Body(content: content)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private nonisolated var _v6Body: VersionedViewV6Body<Content> {
        VersionedViewV6Body(content: content)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    private nonisolated var _v5Body: VersionedViewV5Body<Content> {
        VersionedViewV5Body(content: content)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    private nonisolated var _v4Body: VersionedViewV4Body<Content> {
        VersionedViewV4Body(content: content)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private nonisolated var _v3Body: VersionedViewV3Body<Content> {
        VersionedViewV3Body(content: content)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    private nonisolated var _v2Body: VersionedViewV2Body<Content> {
        VersionedViewV2Body(content: content)
    }

    private nonisolated var _v1Body: VersionedViewV1Body<Content> {
        VersionedViewV1Body(content: content)
    }


    #if DEBUG
    typealias V0Body = UnavailableVersionedViewBody
    #else
    typealias V0Body = EmptyView
    #endif
    nonisolated var _v0Body: V0Body {
        V0Body()
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
        switch version {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return VersionedViewV8_1Body<Content>._makeView(
                    view: view[\._v8_1Body],
                    inputs: inputs
                )
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return VersionedViewV8Body<Content>._makeView(
                    view: view[\._v8Body],
                    inputs: inputs
                )
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return VersionedViewV7Body<Content>._makeView(
                    view: view[\._v7Body],
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return VersionedViewV6Body<Content>._makeView(
                    view: view[\._v6Body],
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return VersionedViewV5Body<Content>._makeView(
                    view: view[\._v5Body],
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return VersionedViewV4Body<Content>._makeView(
                    view: view[\._v4Body],
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return VersionedViewV3Body<Content>._makeView(
                    view: view[\._v3Body],
                    inputs: inputs
                )
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return VersionedViewV2Body<Content>._makeView(
                    view: view[\._v2Body],
                    inputs: inputs
                )
            }
        case .v1:
            return VersionedViewV1Body<Content>._makeView(
                view: view[\._v1Body],
                inputs: inputs
            )
        default:
            break
        }
        return V0Body._makeView(
            view: view[\._v0Body],
            inputs: inputs
        )
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
        switch version {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return VersionedViewV8_1Body<Content>._makeViewList(
                    view: view[\._v8_1Body],
                    inputs: inputs
                )
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return VersionedViewV8Body<Content>._makeViewList(
                    view: view[\._v8Body],
                    inputs: inputs
                )
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return VersionedViewV7Body<Content>._makeViewList(
                    view: view[\._v7Body],
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return VersionedViewV6Body<Content>._makeViewList(
                    view: view[\._v6Body],
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return VersionedViewV5Body<Content>._makeViewList(
                    view: view[\._v5Body],
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return VersionedViewV4Body<Content>._makeViewList(
                    view: view[\._v4Body],
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return VersionedViewV3Body<Content>._makeViewList(
                    view: view[\._v3Body],
                    inputs: inputs
                )
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return VersionedViewV2Body<Content>._makeViewList(
                    view: view[\._v2Body],
                    inputs: inputs
                )
            }
        case .v1:
            return VersionedViewV1Body<Content>._makeViewList(
                view: view[\._v1Body],
                inputs: inputs
            )
        default:
            break
        }
        return V0Body._makeViewList(
            view: view[\._v0Body],
            inputs: inputs
        )
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
        switch version {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return VersionedViewV8_1Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return VersionedViewV8Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return VersionedViewV7Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return VersionedViewV6Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return VersionedViewV5Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return VersionedViewV4Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return VersionedViewV3Body<Content>._viewListCount(
                    inputs: inputs
                )
            }
        case .v2:
            return VersionedViewV2Body<Content>._viewListCount(
                inputs: inputs
            )
        default:
            break
        }
        return V0Body._viewListCount(
            inputs: inputs
        )
    }
}

@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
private struct VersionedViewV8_1Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v8_1Body
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
private struct VersionedViewV8Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v8Body
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private struct VersionedViewV7Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v7Body
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct VersionedViewV6Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v6Body
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
private struct VersionedViewV5Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v5Body
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct VersionedViewV4Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v4Body
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct VersionedViewV3Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v3Body
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct VersionedViewV2Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v2Body
    }
}

private struct VersionedViewV1Body<Content: VersionedView>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.v1Body
    }
}

// MARK: - Previews

struct VersionedView_Previews: PreviewProvider {
    struct PreviewVersionedView: VersionedView {
        var v8Body: some View { Text("V8") }
        var v7Body: some View { Text("V7") }
        var v6Body: some View { Text("V6") }
        var v5Body: some View { Text("V5") }
        var v4Body: some View { Text("V4") }
        var v3Body: some View { Text("V3") }
        var v2Body: some View { Text("V2") }
        var v1Body: some View { Text("V1") }
    }

    struct VersionedViewWithState: VersionedView {
        @State var value = 0

        var v1Body: some View {
            Button {
                value += 1
            } label: {
                Text(value.description)
            }
        }
    }

    static var previews: some View {
        VStack {
            PreviewVersionedView()

            PreviewVersionedView()
                .version(.v8)

            PreviewVersionedView()
                .version(.v7)

            PreviewVersionedView()
                .version(.v6)

            PreviewVersionedView()
                .version(.v5)

            PreviewVersionedView()
                .version(.v4)

            PreviewVersionedView()
                .version(.v3)

            PreviewVersionedView()
                .version(.v2)

            PreviewVersionedView()
                .version(.v1)

            VersionedViewWithState()
        }
        .padding()
        .previewDisplayName("Text")
    }
}
