//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that's `Body` is statically conditional on the user interface idiom.
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifer``
/// to aide with cross platform compatibility.
///
@MainActor @preconcurrency
public protocol UserInterfaceIdiomContent: PrimitiveView {
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

extension UserInterfaceIdiomContent {

    private nonisolated var _phoneBody: UserInterfaceIdiomPhoneContent<Self> {
        UserInterfaceIdiomPhoneContent(content: self)
    }

    private nonisolated var _padBody: UserInterfaceIdiomPadContent<Self> {
        UserInterfaceIdiomPadContent(content: self)
    }

    private nonisolated var _macBody: UserInterfaceIdiomMacContent<Self> {
        UserInterfaceIdiomMacContent(content: self)
    }

    private nonisolated var _tvBody: UserInterfaceIdiomTVContent<Self> {
        UserInterfaceIdiomTVContent(content: self)
    }

    private nonisolated var _watchBody: UserInterfaceIdiomWatchContent<Self> {
        UserInterfaceIdiomWatchContent(content: self)
    }

    private nonisolated var _visionBody: UserInterfaceIdiomVisionContent<Self> {
        UserInterfaceIdiomVisionContent(content: self)
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        #if os(macOS)
        return UserInterfaceIdiomMacContent<Self>._makeView(view: view[\._macBody], inputs: inputs)
        #elseif os(watchOS)
        return UserInterfaceIdiomWatchContent<Self>._makeView(view: view[\._watchBody], inputs: inputs)
        #elseif os(tvOS)
        return UserInterfaceIdiomTVContent<Self>._makeView(view: view[\._tvBody], inputs: inputs)
        #elseif os(visionOS)
        return UserInterfaceIdiomVisionContent<Self>._makeView(view: view[\._visionBody], inputs: inputs)
        #else
        switch UIDevice.currentUserInterfaceIdiom {
        case .phone:
            return UserInterfaceIdiomPhoneContent<Self>._makeView(view: view[\._phoneBody], inputs: inputs)
        case .pad:
            return UserInterfaceIdiomPadContent<Self>._makeView(view: view[\._padBody], inputs: inputs)
        case .mac:
            return UserInterfaceIdiomMacContent<Self>._makeView(view: view[\._macBody], inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        #if os(macOS)
        return UserInterfaceIdiomMacContent<Self>._makeViewList(view: view[\._macBody], inputs: inputs)
        #elseif os(watchOS)
        return UserInterfaceIdiomWatchContent<Self>._makeViewList(view: view[\._watchBody], inputs: inputs)
        #elseif os(tvOS)
        return UserInterfaceIdiomTVContent<Self>._makeViewList(view: view[\._tvBody], inputs: inputs)
        #elseif os(visionOS)
        return UserInterfaceIdiomVisionContent<Self>._makeViewList(view: view[\._visionBody], inputs: inputs)
        #else
        switch UIDevice.currentUserInterfaceIdiom {
        case .phone:
            return UserInterfaceIdiomPhoneContent<Self>._makeViewList(view: view[\._phoneBody], inputs: inputs)
        case .pad:
            return UserInterfaceIdiomPadContent<Self>._makeViewList(view: view[\._padBody], inputs: inputs)
        case .mac:
            return UserInterfaceIdiomMacContent<Self>._makeViewList(view: view[\._macBody], inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        #if os(macOS)
        return UserInterfaceIdiomMacContent<Self>._viewListCount(inputs: inputs)
        #elseif os(watchOS)
        return UserInterfaceIdiomWatchContent<Self>._viewListCount(inputs: inputs)
        #elseif os(tvOS)
        return UserInterfaceIdiomTVContent<Self>._viewListCount(inputs: inputs)
        #elseif os(visionOS)
        return UserInterfaceIdiomVisionContent<Self>._viewListCount(inputs: inputs)
        #else
        switch UIDevice.currentUserInterfaceIdiom {
        case .phone:
            return UserInterfaceIdiomPhoneContent<Self>._viewListCount(inputs: inputs)
        case .pad:
            return UserInterfaceIdiomPadContent<Self>._viewListCount(inputs: inputs)
        case .mac:
            return UserInterfaceIdiomMacContent<Self>._viewListCount(inputs: inputs)
        default:
            preconditionFailure("unsupported")
        }
        #endif
    }
}

#if os(iOS)
extension UIDevice {
    nonisolated static let currentUserInterfaceIdiom: UIUserInterfaceIdiom = {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                UIDevice.current.userInterfaceIdiom
            }
        }
        var idiom: UIUserInterfaceIdiom = .unspecified
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            idiom = UIDevice.current.userInterfaceIdiom
            semaphore.signal()
        }
        semaphore.wait()
        return idiom
    }()
}
#endif

private struct UserInterfaceIdiomPhoneContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.phoneBody
    }
}

private struct UserInterfaceIdiomPadContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.padBody
    }
}

private struct UserInterfaceIdiomMacContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.macBody
    }
}

private struct UserInterfaceIdiomTVContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.tvBody
    }
}


private struct UserInterfaceIdiomWatchContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.watchBody
    }
}


private struct UserInterfaceIdiomVisionContent<Content: UserInterfaceIdiomContent>: View {
    nonisolated(unsafe) var content: Content

    var body: some View {
        content.visionBody
    }
}
