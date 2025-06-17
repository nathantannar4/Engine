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
/// By default, unsupported versions will resolve to `Content`. Supported
/// versions that don't have their body implemented will resolve to the next
/// version body that is implemented.
///
/// > Tip: Use ``VersionedView`` and ``VersionedViewModifier``
/// to aide with backwards compatibility.
///
@MainActor @preconcurrency
public protocol VersionedViewModifier: ViewModifier {

    associatedtype V7Body: View = V6Body

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @ViewBuilder @MainActor @preconcurrency func v7Body(content: Content) -> V7Body

    associatedtype V6Body: View = V5Body

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @ViewBuilder @MainActor @preconcurrency func v6Body(content: Content) -> V6Body

    associatedtype V5Body: View = V4Body

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @ViewBuilder @MainActor @preconcurrency func v5Body(content: Content) -> V5Body

    associatedtype V4Body: View = V3Body

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder @MainActor @preconcurrency func v4Body(content: Content) -> V4Body

    associatedtype V3Body: View = V2Body

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder @MainActor @preconcurrency func v3Body(content: Content) -> V3Body

    associatedtype V2Body: View = V1Body

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder @MainActor @preconcurrency func v2Body(content: Content) -> V2Body

    associatedtype V1Body: View = Content

    @ViewBuilder @MainActor @preconcurrency func v1Body(content: Content) -> V1Body
}

extension VersionedViewModifier where V7Body == V6Body {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public func v7Body(content: Content) -> V7Body {
        v6Body(content: content)
    }
}

extension VersionedViewModifier where V6Body == V5Body {
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    public func v6Body(content: Content) -> V6Body {
        v5Body(content: content)
    }
}

extension VersionedViewModifier where V5Body == V4Body {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
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

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    public var v7Body: Modifier.V7Body {
        modifier.v7Body(content: content)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    public var v6Body: Modifier.V6Body {
        modifier.v6Body(content: content)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
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

struct VersionedViewModifier_Previews: PreviewProvider {
    struct UnderlineModifier: VersionedViewModifier {

        @State var isActive = true

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        func v4Body(content: Content) -> some View {
            content
                .underline(isActive)
                .onTapGesture {
                    isActive.toggle()
                }
        }

        // Add support for a semi-equivalent version for iOS 13-15
        func v1Body(content: Content) -> some View {
            content
                .background(
                    Rectangle()
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                )
        }
    }

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(UnderlineModifier())

            Text("Hello, World")
                .modifier(UnderlineModifier())
                .version(.v1)

            VariadicViewAdapter {
                Text("Line 1")
                Text("Line 2")
            } content: { source in
                HStack(spacing: 8) {
                    ForEachSubview(source) { index, subview in
                        subview
                            .modifier(UnderlineModifier())

                        if index < source.count - 1 {
                            Circle()
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
        }
    }
}
