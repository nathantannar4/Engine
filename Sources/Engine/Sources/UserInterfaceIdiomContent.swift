//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that's `Body` is statically conditional on the user interface idiom.
///
/// > Important: The only `DynamicProperty` a `UserInterfaceIdiomContent`
/// can only contain is a `Binding`
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifer``
/// to aide with cross platform compatibility.
///
@MainActor @preconcurrency
public protocol UserInterfaceIdiomContent: PrimitiveView where Body == Never {
    associatedtype PhoneBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var phoneBody: PhoneBody { get }

    associatedtype PadBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var padBody: PadBody { get }

    associatedtype MacBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var macBody: MacBody { get }

    associatedtype TvBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var tvBody: TvBody { get }

    associatedtype WatchBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var watchBody: WatchBody { get }

    associatedtype VisionBody: View = EmptyView
    @ViewBuilder @MainActor @preconcurrency var visionBody: VisionBody { get }
}

extension UserInterfaceIdiomContent where PhoneBody == EmptyView {
    public var phoneBody: PhoneBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where PadBody == EmptyView {
    public var padBody: PadBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where MacBody == EmptyView {
    public var macBody: MacBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where TvBody == EmptyView {
    public var tvBody: TvBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where WatchBody == EmptyView {
    public var watchBody: WatchBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where VisionBody == EmptyView {
    public var visionBody: VisionBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where Body == Never{
    public var body: Never {
        bodyError()
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        #if os(macOS)
        return MacBody._makeView(view: view[\.macBody], inputs: inputs)
        #elseif os(watchOS)
        return WatchBody._makeView(view: view[\.watchBody], inputs: inputs)
        #elseif os(tvOS)
        return TvBody._makeView(view: view[\.tvBody], inputs: inputs)
        #elseif os(visionOS)
        return VisionBody._makeView(view: view[\.visionBody], inputs: inputs)
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._makeView(view: view[\.phoneBody], inputs: inputs)
        case .pad:
            return PadBody._makeView(view: view[\.padBody], inputs: inputs)
        case .mac:
            return MacBody._makeView(view: view[\.macBody], inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        #if os(macOS)
        return MacBody._makeViewList(view: view[\.macBody], inputs: inputs)
        #elseif os(watchOS)
        return WatchBody._makeViewList(view: view[\.watchBody], inputs: inputs)
        #elseif os(tvOS)
        return TvBody._makeViewList(view: view[\.tvBody], inputs: inputs)
        #elseif os(visionOS)
        return VisionBody._makeViewList(view: view[\.visionBody], inputs: inputs)
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._makeViewList(view: view[\.phoneBody], inputs: inputs)
        case .pad:
            return PadBody._makeViewList(view: view[\.padBody], inputs: inputs)
        case .mac:
            return MacBody._makeViewList(view: view[\.macBody], inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        #if os(macOS)
        return MacBody._viewListCount(inputs: inputs)
        #elseif os(watchOS)
        return WatchBody._viewListCount(inputs: inputs)
        #elseif os(tvOS)
        return TvBody._viewListCount(inputs: inputs)
        #elseif os(visionOS)
        return VisionBody._viewListCount(inputs: inputs)
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._viewListCount(inputs: inputs)
        case .pad:
            return PadBody._viewListCount(inputs: inputs)
        case .mac:
            return MacBody._viewListCount(inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }
}
