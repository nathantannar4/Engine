//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view whose `Body` is statically conditional on the user interface idiom.
///
/// On iOS, the body is selected using the current device's user interface idiom,
/// where only the phone, pad and mac idioms are supported.
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifier``
/// to aid with cross platform compatibility.
///
public protocol UserInterfaceIdiomContent: PrimitiveView {
    /// The type of view representing the body on iPhone.
    associatedtype PhoneBody: View = EmptyView
    /// The content of the view on iPhone.
    @ViewBuilder @MainActor @preconcurrency var phoneBody: PhoneBody { get }

    /// The type of view representing the body on iPad.
    associatedtype PadBody: View = EmptyView
    /// The content of the view on iPad.
    @ViewBuilder @MainActor @preconcurrency var padBody: PadBody { get }

    /// The type of view representing the body on Mac.
    associatedtype MacBody: View = EmptyView
    /// The content of the view on Mac.
    @ViewBuilder @MainActor @preconcurrency var macBody: MacBody { get }

    /// The type of view representing the body on Apple TV.
    associatedtype TvBody: View = EmptyView
    /// The content of the view on Apple TV.
    @ViewBuilder @MainActor @preconcurrency var tvBody: TvBody { get }

    /// The type of view representing the body on Apple Watch.
    associatedtype WatchBody: View = EmptyView
    /// The content of the view on Apple Watch.
    @ViewBuilder @MainActor @preconcurrency var watchBody: WatchBody { get }

    /// The type of view representing the body on visionOS.
    associatedtype VisionBody: View = EmptyView
    /// The content of the view on visionOS.
    @ViewBuilder @MainActor @preconcurrency var visionBody: VisionBody { get }
}

extension UserInterfaceIdiomContent where PhoneBody == EmptyView {
    /// By default, the view is empty on iPhone.
    public var phoneBody: PhoneBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where PadBody == EmptyView {
    /// By default, the view is empty on iPad.
    public var padBody: PadBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where MacBody == EmptyView {
    /// By default, the view is empty on Mac.
    public var macBody: MacBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where TvBody == EmptyView {
    /// By default, the view is empty on Apple TV.
    public var tvBody: TvBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where WatchBody == EmptyView {
    /// By default, the view is empty on Apple Watch.
    public var watchBody: WatchBody {
        EmptyView()
    }
}

extension UserInterfaceIdiomContent where VisionBody == EmptyView {
    /// By default, the view is empty on visionOS.
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
        let storage = SendableStorage<UIUserInterfaceIdiom>()
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            storage.value = UIDevice.current.userInterfaceIdiom
            semaphore.signal()
        }
        semaphore.wait()
        return storage.value
    }()
}

private class SendableStorage<T>: @unchecked Sendable {
    var value: T!
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

// MARK: - Previews

struct UserInterfaceIdiomContent_Previews: PreviewProvider {
    struct PreviewUserInterfaceIdiomContent: UserInterfaceIdiomContent {
        var phoneBody: some View { Text("iOS") }
        var padBody: some View { Text("iPadOS") }
        var macBody: some View { Text("macOS") }
        var tvBody: some View { Text("tvOS") }
        var watchBody: some View { Text("watchOS") }
        var visionBody: some View { Text("visionOS") }
    }

    struct UserInterfaceIdiomContentWithState: UserInterfaceIdiomContent {
        @State var value = 0

        var phoneBody: some View {
            Button {
                value += 1
            } label: {
                Text(value.description)
            }
        }
    }

    static var previews: some View {
        VStack {
            PreviewUserInterfaceIdiomContent()

            UserInterfaceIdiomContentWithState()
        }
    }
}
