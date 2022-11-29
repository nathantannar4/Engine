//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that's `Body` is statically conditional on the user interface idiom.
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifer``
/// to aide with cross platform compatibility.
///
public protocol UserInterfaceIdiomContent: View where Body == Never {
    associatedtype PhoneBody: View = EmptyView
    @ViewBuilder var phoneBody: PhoneBody { get }

    associatedtype PadBody: View = EmptyView
    @ViewBuilder var padBody: PadBody { get }

    associatedtype MacBody: View = EmptyView
    @ViewBuilder var macBody: MacBody { get }

    associatedtype TvBody: View = EmptyView
    @ViewBuilder var tvBody: TvBody { get }

    associatedtype WatchBody: View = EmptyView
    @ViewBuilder var watchBody: WatchBody { get }
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

extension UserInterfaceIdiomContent where Body == Never{
    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        #if os(macOS)
        return MacBody._makeView(view: view[\.macBody], inputs: inputs)
        #elseif !os(watchOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._makeView(view: view[\.phoneBody], inputs: inputs)
        case .pad:
            return PadBody._makeView(view: view[\.padBody], inputs: inputs)
        case .mac:
            return MacBody._makeView(view: view[\.macBody], inputs: inputs)
        case .tv:
            return TvBody._makeView(view: view[\.tvBody], inputs: inputs)
        case .unspecified, .carPlay:
            fallthrough
        @unknown default:
            preconditionFailure("unsupported")
        }
        #elseif os(watchOS)
        return WatchBody._makeView(view: view[\.watchBody], inputs: inputs)
        #endif
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        #if os(macOS)
        return MacBody._makeViewList(view: view[\.macBody], inputs: inputs)
        #elseif !os(watchOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._makeViewList(view: view[\.phoneBody], inputs: inputs)
        case .pad:
            return PadBody._makeViewList(view: view[\.padBody], inputs: inputs)
        case .mac:
            return MacBody._makeViewList(view: view[\.macBody], inputs: inputs)
        case .tv:
            return TvBody._makeViewList(view: view[\.tvBody], inputs: inputs)
        case .unspecified, .carPlay:
            fallthrough
        @unknown default:
            preconditionFailure("unsupported")
        }
        #elseif os(watchOS)
        return WatchBody._makeViewList(view: view[\.watchBody], inputs: inputs)
        #endif
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        #if os(macOS)
        return MacBody._viewListCount(inputs: inputs)
        #elseif !os(watchOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return PhoneBody._viewListCount(inputs: inputs)
        case .pad:
            return PadBody._viewListCount(inputs: inputs)
        case .mac:
            return MacBody._viewListCount(inputs: inputs)
        case .tv:
            return TvBody._viewListCount(inputs: inputs)
        case .unspecified, .carPlay:
            fallthrough
        @unknown default:
            preconditionFailure("unsupported")
        }
        #elseif os(watchOS)
        return WatchBody._viewListCount(inputs: inputs)
        #endif
    }
}
