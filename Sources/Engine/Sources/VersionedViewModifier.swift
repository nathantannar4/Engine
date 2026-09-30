//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier whose `Body` is statically conditional on version availability.
///
/// Because the modifier is statically conditional, `AnyView` is not needed
/// for type erasure. This is unlike `@ViewBuilder` which requires an
/// `if #available(...)` conditional to be type-erased by `AnyView`.
///
/// By default, unsupported versions will resolve to `Content`. Supported
/// versions that don't have their body implemented will resolve to the next
/// version body that is implemented.
///
/// > Tip: Use ``VersionedView`` and ``VersionedViewModifier``
/// to aid with backwards compatibility.
///
public protocol VersionedViewModifier: ViewModifier {

    /// The type of view representing the body on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    associatedtype V8_1Body: View = V8Body

    /// The content and behavior of the modifier on iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    ///
    /// Defaults to ``v8Body(content:)``.
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    @ViewBuilder @MainActor @preconcurrency func v8_1Body(content: Content) -> V8_1Body

    /// The type of view representing the body on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    associatedtype V8Body: View = V7Body

    /// The content and behavior of the modifier on iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    ///
    /// Defaults to ``v7Body(content:)``.
    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    @ViewBuilder @MainActor @preconcurrency func v8Body(content: Content) -> V8Body

    /// The type of view representing the body on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    associatedtype V7Body: View = V6Body

    /// The content and behavior of the modifier on iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    ///
    /// Defaults to ``v6Body(content:)``.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @ViewBuilder @MainActor @preconcurrency func v7Body(content: Content) -> V7Body

    /// The type of view representing the body on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    associatedtype V6Body: View = V5Body

    /// The content and behavior of the modifier on iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    ///
    /// Defaults to ``v5Body(content:)``.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @ViewBuilder @MainActor @preconcurrency func v6Body(content: Content) -> V6Body

    /// The type of view representing the body on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    associatedtype V5Body: View = V4Body

    /// The content and behavior of the modifier on iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    ///
    /// Defaults to ``v4Body(content:)``.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @ViewBuilder @MainActor @preconcurrency func v5Body(content: Content) -> V5Body

    /// The type of view representing the body on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    associatedtype V4Body: View = V3Body

    /// The content and behavior of the modifier on iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    ///
    /// Defaults to ``v3Body(content:)``.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder @MainActor @preconcurrency func v4Body(content: Content) -> V4Body

    /// The type of view representing the body on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    associatedtype V3Body: View = V2Body

    /// The content and behavior of the modifier on iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    ///
    /// Defaults to ``v2Body(content:)``.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder @MainActor @preconcurrency func v3Body(content: Content) -> V3Body

    /// The type of view representing the body on iOS 14, macOS 11, tvOS 14 and watchOS 7 or later.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    associatedtype V2Body: View = V1Body

    /// The content and behavior of the modifier on iOS 14, macOS 11, tvOS 14 and watchOS 7 or later.
    ///
    /// Defaults to ``v1Body(content:)``.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder @MainActor @preconcurrency func v2Body(content: Content) -> V2Body

    /// The type of view representing the body on the minimum supported OS versions.
    associatedtype V1Body: View = Content

    /// The content and behavior of the modifier on the minimum supported OS versions.
    ///
    /// Defaults to the unmodified `content`.
    @ViewBuilder @MainActor @preconcurrency func v1Body(content: Content) -> V1Body
}

@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
extension VersionedViewModifier where V8_1Body == V8Body {
    public func v8_1Body(content: Content) -> V8Body {
        v8Body(content: content)
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
extension VersionedViewModifier where V8Body == V7Body {
    public func v8Body(content: Content) -> V8Body {
        v7Body(content: content)
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension VersionedViewModifier where V7Body == V6Body {
    public func v7Body(content: Content) -> V7Body {
        v6Body(content: content)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension VersionedViewModifier where V6Body == V5Body {
    public func v6Body(content: Content) -> V6Body {
        v5Body(content: content)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension VersionedViewModifier where V5Body == V4Body {
    public func v5Body(content: Content) -> V5Body {
        v4Body(content: content)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VersionedViewModifier where V4Body == V3Body {
    public func v4Body(content: Content) -> V4Body {
        v3Body(content: content)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VersionedViewModifier where V3Body == V2Body {
    public func v3Body(content: Content) -> V3Body {
        v2Body(content: content)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension VersionedViewModifier where V2Body == V1Body {
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

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    public var v8_1Body: Modifier.V8_1Body {
        modifier.v8_1Body(content: content)
    }

    @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
    public var v8Body: Modifier.V8Body {
        modifier.v8Body(content: content)
    }

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
