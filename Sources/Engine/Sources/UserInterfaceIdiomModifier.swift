//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that's `Body` is statically conditional on the user interface idiom.
///
/// > Tip: Use ``UserInterfaceIdiomContent`` and ``UserInterfaceIdiomModifer``
/// to aide with cross platform compatibility.
///
public protocol UserInterfaceIdiomModifier: ViewModifier {
    associatedtype PhoneBody: View = Content
    @ViewBuilder func phoneBody(content: Content) -> PhoneBody

    associatedtype PadBody: View = Content
    @ViewBuilder func padBody(content: Content) -> PadBody

    associatedtype MacBody: View = Content
    @ViewBuilder func macBody(content: Content) -> MacBody

    associatedtype TvBody: View = Content
    @ViewBuilder func tvBody(content: Content) -> TvBody

    associatedtype CarBody: View = Content
    @ViewBuilder func carBody(content: Content) -> CarBody
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

extension UserInterfaceIdiomModifier where CarBody == Content {
    public func carBody(content: Content) -> CarBody {
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

    public var carBody: Modifier.CarBody {
        modifier.carBody(content: content)
    }
}
