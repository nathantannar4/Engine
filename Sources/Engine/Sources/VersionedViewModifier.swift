//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that's `Body` is statically conditional on version availability
///
/// Because the modifier is statically conditional, `AnyView` is not needed
/// for type erasure. This is unlike `@ViewBuilder` which  requires an
/// `if #available(...)` conditional to be type-erased by `AnyView`.
///
/// > Important: The only `DynamicProperty` a `VersionedViewModifier`
/// can only contain is a `Binding`
///
/// By default, unsupported versions will resolve to `Content`. Supported
/// versions that don't have their body implemented will resolve to the next
/// version body that is implemented.
///
/// > Tip: Use ``VersionedView`` and ``VersionedViewModifier``
/// to aide with backwards compatibility.
///
public protocol VersionedViewModifier: ViewModifier {
    associatedtype V5Body: View = V4Body

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @ViewBuilder func v5Body(content: Content) -> V5Body

    associatedtype V4Body: View = V3Body

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder func v4Body(content: Content) -> V4Body

    associatedtype V3Body: View = V2Body

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder func v3Body(content: Content) -> V3Body

    associatedtype V2Body: View = V1Body

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder func v2Body(content: Content) -> V2Body

    associatedtype V1Body: View = Content

    @ViewBuilder func v1Body(content: Content) -> V1Body
}

extension VersionedViewModifier where V5Body == V4Body {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public func v5Body(content: Content) -> V5Body {
        v4Body(content: content)
    }
}

extension VersionedViewModifier where V4Body == V3Body {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func v4Body(content: Content) -> V4Body {
        v3Body(content: content)
    }
}

extension VersionedViewModifier where V3Body == V2Body {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func v3Body(content: Content) -> V3Body {
        v2Body(content: content)
    }
}

extension VersionedViewModifier where V2Body == V1Body {
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func v2Body(content: Content) -> V2Body {
        v1Body(content: content)
    }
}

extension VersionedViewModifier where V1Body == Content {
    public func v1Body(content: Content) -> V1Body {
        content
    }
}

extension VersionedViewModifier where Body == _VersionedViewModifierBody<Self> {
    public func body(content: Content) -> _VersionedViewModifierBody<Self> {
        _VersionedViewModifierBody(content: content, modifier: self)
    }
}

@frozen
public struct _VersionedViewModifierBody<Modifier: VersionedViewModifier>: VersionedView {

    var content: Modifier.Content
    var modifier: Modifier

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var v5Body: Modifier.V5Body {
        modifier.v5Body(content: content)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: Modifier.V4Body {
        modifier.v4Body(content: content)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var v3Body: Modifier.V3Body {
        modifier.v3Body(content: content)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public var v2Body: Modifier.V2Body {
        modifier.v2Body(content: content)
    }

    public var v1Body: Modifier.V1Body {
        modifier.v1Body(content: content)
    }
}

// MARK: - Previews

struct UnderlineModifier: VersionedViewModifier {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func v4Body(content: Content) -> some View {
        content.underline()
    }
}

struct VersionedViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(UnderlineModifier())
        }
    }
}
