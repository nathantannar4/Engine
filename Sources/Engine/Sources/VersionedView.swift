//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that's `Body` is statically conditional on version availability
///
/// Because the view is statically conditional, `AnyView` is not needed
/// for type erasure. This is unlike `@ViewBuilder` which  requires an
/// `if #available(...)` conditional to be type-erased by `AnyView`.
///
/// By default, unsupported versions will resolve to `EmptyView`. Supported
/// versions that don't have their body implemented will resolve to the next
/// version body that is implemented.
///
/// > Tip: Use ``VersionedView`` and ``VersionedViewModifier``
/// to aide with backwards compatibility.
///
@MainActor @preconcurrency
public protocol VersionedView: View {

    associatedtype V7Body: View = V6Body

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @ViewBuilder @MainActor @preconcurrency var v7Body: V7Body { get }

    associatedtype V6Body: View = V5Body

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @ViewBuilder @MainActor @preconcurrency var v6Body: V6Body { get }

    associatedtype V5Body: View = V4Body

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @ViewBuilder @MainActor @preconcurrency var v5Body: V5Body { get }

    associatedtype V4Body: View = V3Body

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder @MainActor @preconcurrency var v4Body: V4Body { get }

    associatedtype V3Body: View = V2Body

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder @MainActor @preconcurrency var v3Body: V3Body { get }

    associatedtype V2Body: View = V1Body

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder @MainActor @preconcurrency var v2Body: V2Body { get }

    associatedtype V1Body: View = EmptyView

    @ViewBuilder @MainActor @preconcurrency var v1Body: V1Body { get }
}

extension VersionedView where V7Body == V6Body {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public var v7Body: V6Body { v6Body }
}

extension VersionedView where V6Body == V5Body {
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    public var v6Body: V6Body { v5Body }
}

extension VersionedView where V5Body == V4Body {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public var v5Body: V5Body { v4Body }
}

extension VersionedView where V4Body == V3Body {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: V4Body { v3Body }
}

extension VersionedView where V3Body == V2Body {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var v3Body: V3Body { v2Body }
}

extension VersionedView where V2Body == V1Body {
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
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

public struct _VersionedViewBody<Content: VersionedView>: PrimitiveView {

    var content: Content

    #if DEBUG
    var unsupported: UnsupportedVersionView {
        UnsupportedVersionView()
    }
    #endif

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        #if !DEBUG
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return Content.V7Body._makeView(
                view: view[\.content.v7Body],
                inputs: inputs
            )
        } else if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return Content.V6Body._makeView(
                view: view[\.content.v6Body],
                inputs: inputs
            )
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return Content.V5Body._makeView(
                view: view[\.content.v5Body],
                inputs: inputs
            )
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return Content.V4Body._makeView(
                view: view[\.content.v4Body],
                inputs: inputs
            )
        } else if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return Content.V3Body._makeView(
                view: view[\.content.v3Body],
                inputs: inputs
            )
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return Content.V2Body._makeView(
                view: view[\.content.v2Body],
                inputs: inputs
            )
        } else {
            return Content.V1Body._makeView(
                view: view[\.content.v1Body],
                inputs: inputs
            )
        }
        #else
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        switch version {
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return Content.V7Body._makeView(
                    view: view[\.content.v7Body],
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return Content.V6Body._makeView(
                    view: view[\.content.v6Body],
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                return Content.V5Body._makeView(
                    view: view[\.content.v5Body],
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return Content.V4Body._makeView(
                    view: view[\.content.v4Body],
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return Content.V3Body._makeView(
                    view: view[\.content.v3Body],
                    inputs: inputs
                )
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return Content.V2Body._makeView(
                    view: view[\.content.v2Body],
                    inputs: inputs
                )
            }
        case .v1:
            return Content.V1Body._makeView(
                view: view[\.content.v1Body],
                inputs: inputs
            )
        default:
            break
        }
        return UnsupportedVersionView._makeView(
            view: view[\.unsupported],
            inputs: inputs
        )
        #endif
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        #if !DEBUG
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return Content.V7Body._makeViewList(
                view: view[\.content.v7Body],
                inputs: inputs
            )
        } else if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return Content.V6Body._makeViewList(
                view: view[\.content.v6Body],
                inputs: inputs
            )
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return Content.V5Body._makeViewList(
                view: view[\.content.v5Body],
                inputs: inputs
            )
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return Content.V4Body._makeViewList(
                view: view[\.content.v4Body],
                inputs: inputs
            )
        } else if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return Content.V3Body._makeViewList(
                view: view[\.content.v3Body],
                inputs: inputs
            )
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return Content.V2Body._makeViewList(
                view: view[\.content.v2Body],
                inputs: inputs
            )
        } else {
            return Content.V1Body._makeViewList(
                view: view[\.content.v1Body],
                inputs: inputs
            )
        }
        #else
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        switch version {
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return Content.V7Body._makeViewList(
                    view: view[\.content.v7Body],
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return Content.V6Body._makeViewList(
                    view: view[\.content.v6Body],
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                return Content.V5Body._makeViewList(
                    view: view[\.content.v5Body],
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return Content.V4Body._makeViewList(
                    view: view[\.content.v4Body],
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return Content.V3Body._makeViewList(
                    view: view[\.content.v3Body],
                    inputs: inputs
                )
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return Content.V2Body._makeViewList(
                    view: view[\.content.v2Body],
                    inputs: inputs
                )
            }
        case .v1:
            return Content.V1Body._makeViewList(
                view: view[\.content.v1Body],
                inputs: inputs
            )
        default:
            break
        }
        return UnsupportedVersionView._makeViewList(view: view[\.unsupported], inputs: inputs)
        #endif
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        #if !DEBUG
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return Content.V7Body._viewListCount(
                inputs: inputs
            )
        } else if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return Content.V6Body._viewListCount(
                inputs: inputs
            )
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            return Content.V5Body._viewListCount(
                inputs: inputs
            )
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return Content.V4Body._viewListCount(
                inputs: inputs
            )
        } else if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return Content.V3Body._viewListCount(
                inputs: inputs
            )
        } else {
            return Content.V2Body._viewListCount(
                inputs: inputs
            )
        }
        #else
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        switch version {
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return Content.V7Body._viewListCount(
                    inputs: inputs
                )
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return Content.V6Body._viewListCount(
                    inputs: inputs
                )
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return Content.V5Body._viewListCount(
                    inputs: inputs
                )
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return Content.V4Body._viewListCount(
                    inputs: inputs
                )
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return Content.V3Body._viewListCount(
                    inputs: inputs
                )
            }
        case .v2:
            return Content.V2Body._viewListCount(
                inputs: inputs
            )
        default:
            break
        }
        return UnsupportedVersionView._viewListCount(
            inputs: inputs
        )
        #endif
    }
}

// MARK: - Previews

struct VersionedView_Previews: PreviewProvider {
    struct PreviewVersionedView: VersionedView {
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
                .version(.v1)

            VersionedViewWithState()
        }
        .padding()
        .previewDisplayName("Text")
    }
}
