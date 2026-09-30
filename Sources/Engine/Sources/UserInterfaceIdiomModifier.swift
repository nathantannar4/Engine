//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier whose `Body` is statically conditional on the user interface idiom.
///
/// On iOS, the body is selected using the current device's user interface idiom,
/// where only the phone, pad and mac idioms are supported.
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifier``
/// to aid with cross platform compatibility.
///
public protocol UserInterfaceIdiomModifier: ViewModifier {
    /// The type of view representing the body on iPhone.
    associatedtype PhoneBody: View = Content
    /// Returns the modified content on iPhone.
    @ViewBuilder @MainActor @preconcurrency func phoneBody(content: Content) -> PhoneBody

    /// The type of view representing the body on iPad.
    associatedtype PadBody: View = Content
    /// Returns the modified content on iPad.
    @ViewBuilder @MainActor @preconcurrency func padBody(content: Content) -> PadBody

    /// The type of view representing the body on Mac.
    associatedtype MacBody: View = Content
    /// Returns the modified content on Mac.
    @ViewBuilder @MainActor @preconcurrency func macBody(content: Content) -> MacBody

    /// The type of view representing the body on Apple TV.
    associatedtype TvBody: View = Content
    /// Returns the modified content on Apple TV.
    @ViewBuilder @MainActor @preconcurrency func tvBody(content: Content) -> TvBody

    /// The type of view representing the body on Apple Watch.
    associatedtype WatchBody: View = Content
    /// Returns the modified content on Apple Watch.
    @ViewBuilder @MainActor @preconcurrency func watchBody(content: Content) -> WatchBody

    /// The type of view representing the body on visionOS.
    associatedtype VisionBody: View = Content
    /// Returns the modified content on visionOS.
    @ViewBuilder @MainActor @preconcurrency func visionBody(content: Content) -> VisionBody
}

extension UserInterfaceIdiomModifier where PhoneBody == Content {
    /// By default, the content is unmodified on iPhone.
    public func phoneBody(content: Content) -> PhoneBody {
        content
    }
}

extension UserInterfaceIdiomModifier where PadBody == Content {
    /// By default, the content is unmodified on iPad.
    public func padBody(content: Content) -> PadBody {
        content
    }
}

extension UserInterfaceIdiomModifier where MacBody == Content {
    /// By default, the content is unmodified on Mac.
    public func macBody(content: Content) -> MacBody {
        content
    }
}

extension UserInterfaceIdiomModifier where TvBody == Content {
    /// By default, the content is unmodified on Apple TV.
    public func tvBody(content: Content) -> TvBody {
        content
    }
}

extension UserInterfaceIdiomModifier where WatchBody == Content {
    /// By default, the content is unmodified on Apple Watch.
    public func watchBody(content: Content) -> WatchBody {
        content
    }
}

extension UserInterfaceIdiomModifier where VisionBody == Content {
    /// By default, the content is unmodified on visionOS.
    public func visionBody(content: Content) -> VisionBody {
        content
    }
}

extension UserInterfaceIdiomModifier where Body == _UserInterfaceIdiomModifierBody<Self> {
    public func body(content: Content) -> _UserInterfaceIdiomModifierBody<Self> {
        _UserInterfaceIdiomModifierBody(content: content, modifier: self)
    }
}

@frozen
public struct _UserInterfaceIdiomModifierBody<Modifier: UserInterfaceIdiomModifier>: UserInterfaceIdiomContent {

    var content: Modifier.Content
    var modifier: Modifier

    public var phoneBody: Modifier.PhoneBody {
        modifier.phoneBody(content: content)
    }

    public var padBody: Modifier.PadBody {
        modifier.padBody(content: content)
    }

    public var macBody: Modifier.MacBody {
        modifier.macBody(content: content)
    }

    public var tvBody: Modifier.TvBody {
        modifier.tvBody(content: content)
    }

    public var watchBody: Modifier.WatchBody {
        modifier.watchBody(content: content)
    }

    public var visionBody: Modifier.VisionBody {
        modifier.visionBody(content: content)
    }
}
