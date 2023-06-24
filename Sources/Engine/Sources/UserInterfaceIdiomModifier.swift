//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that's `Body` is statically conditional on the user interface idiom.
///
/// > Important: The only `DynamicProperty` a `UserInterfaceIdiomModifier`
/// can only contain is a `Binding`
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifer``
/// to aide with cross platform compatibility.
///
public protocol UserInterfaceIdiomModifier: ViewModifier {
    associatedtype PhoneBody: View = Content
    @MainActor @ViewBuilder func phoneBody(content: Content) -> PhoneBody

    associatedtype PadBody: View = Content
    @MainActor @ViewBuilder func padBody(content: Content) -> PadBody

    associatedtype MacBody: View = Content
    @MainActor @ViewBuilder func macBody(content: Content) -> MacBody

    associatedtype TvBody: View = Content
    @MainActor @ViewBuilder func tvBody(content: Content) -> TvBody

    associatedtype WatchBody: View = Content
    @MainActor @ViewBuilder func watchBody(content: Content) -> WatchBody

    associatedtype VisionBody: View = Content
    @MainActor @ViewBuilder func visionBody(content: Content) -> VisionBody
}

extension UserInterfaceIdiomModifier where PhoneBody == Content {
    public func phoneBody(content: Content) -> PhoneBody {
        content
    }
}

extension UserInterfaceIdiomModifier where PadBody == Content {
    public func padBody(content: Content) -> PadBody {
        content
    }
}

extension UserInterfaceIdiomModifier where MacBody == Content {
    public func macBody(content: Content) -> MacBody {
        content
    }
}

extension UserInterfaceIdiomModifier where TvBody == Content {
    public func tvBody(content: Content) -> TvBody {
        content
    }
}

extension UserInterfaceIdiomModifier where WatchBody == Content {
    public func watchBody(content: Content) -> WatchBody {
        content
    }
}

extension UserInterfaceIdiomModifier where VisionBody == Content {
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
