//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A configuration of the Liquid Glass material.
///
/// A back-port of `SwiftUI.Glass` that can be referenced on earlier platforms.
///
@available(iOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in Glass")
@available(macOS, introduced: 10.15, deprecated: 26.0, message: "Please use the built in Glass")
@available(tvOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in Glass")
@available(watchOS, introduced: 6.0, deprecated: 26.0, message: "Please use the built in Glass")
@frozen
public struct VersionedGlass: Equatable, Sendable {

    /// The variant of glass.
    @frozen
    public enum Style: Equatable, Sendable {
        /// Content remains unaffected, as if no glass effect was applied.
        case identity
        /// The regular variant of glass.
        case regular
        /// The clear variant of glass.
        case clear

#if XCODE_26
        /// Converts the style to the corresponding `SwiftUI.Glass`.
        @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
        @available(visionOS, unavailable)
        public func toSwiftUI() -> SwiftUI.Glass {
            switch self {
            case .identity:
                return .identity
            case .regular:
                return .regular
            case .clear:
                return .clear
            }
        }
#endif
    }
    /// The variant of the glass.
    public var style: Style
    /// The tint color of the glass, if any.
    public var tintColor: Color?
    /// Whether the glass reacts to user interaction.
    public var isInteractive: Bool = false

    @inlinable
    public init(
        style: Style,
        tintColor: Color? = nil,
        isInteractive: Bool = false
    ) {
        self.style = style
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    /// The regular variant of glass.
    ///
    /// The regular variant of glass automatically maintains legibility
    /// of content by adjusting its content based on the luminosity of the
    ///  content beneath the glass.
    public static let regular = VersionedGlass(style: .regular)

    /// The clear variant of glass.
    ///
    /// When using clear glass, ensure content remains legible by adding a
    /// dimming layer or other treatment beneath the glass.
    ///
    /// For example, you could add a transparent black color beneath your
    /// glass to ensure content remains legible above the glass.
    ///
    ///     Label("Flag", systemImage: "flag.fill")
    ///         .padding()
    ///         .glassEffect(.clear)
    ///         .background(.black.opacity(0.3))
    ///
    public static let clear = VersionedGlass(style: .clear)

    /// The identity variant of glass. When applied, your content
    /// remains unaffected as if no glass effect was applied.
    public static let identity = VersionedGlass(style: .identity)

    /// Returns a copy of the glass with the provided tint color.
    public func tint(_ color: Color?) -> VersionedGlass {
        var copy = self
        copy.tintColor = color
        return copy
    }

    /// Returns a copy of the glass configured to be interactive.
    public func interactive(_ isInteractive: Bool = true) -> VersionedGlass {
        var copy = self
        copy.isInteractive = isInteractive
        return copy
    }

#if XCODE_26
    /// Converts the glass to the corresponding `SwiftUI.Glass`.
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
    @available(visionOS, unavailable)
    public func toSwiftUI() -> SwiftUI.Glass {
        style.toSwiftUI().tint(tintColor).interactive(isInteractive)
    }
#endif
}

/// The default shape applied by glass effects, a capsule.
@available(iOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in DefaultGlassEffectShape")
@available(macOS, introduced: 10.15, deprecated: 26.0, message: "Please use the built in DefaultGlassEffectShape")
@available(tvOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in DefaultGlassEffectShape")
@available(watchOS, introduced: 6.0, deprecated: 26.0, message: "Please use the built in DefaultGlassEffectShape")
@frozen
public struct VersionedDefaultGlassEffectShape: Shape {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public nonisolated static var role: ShapeRole {
#if XCODE_26 && !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            return DefaultGlassEffectShape.role
        }
#endif
        return Capsule.role
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public nonisolated var layoutDirectionBehavior: LayoutDirectionBehavior {
#if XCODE_26 && !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            return DefaultGlassEffectShape().layoutDirectionBehavior
        }
#endif
        return Capsule().layoutDirectionBehavior
    }

    @inlinable
    public init() { }

    public nonisolated func path(in rect: CGRect) -> Path {
#if XCODE_26 && !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            return DefaultGlassEffectShape().path(in: rect)
        }
#endif
        return Capsule().path(in: rect)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public nonisolated func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
#if XCODE_26 && !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            return DefaultGlassEffectShape().sizeThatFits(proposal)
        }
#endif
        return Capsule().sizeThatFits(proposal)
    }
}

/// A modifier that applies a glass effect in a shape when available.
@available(iOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(macOS, introduced: 10.15, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(tvOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(watchOS, introduced: 6.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@frozen
public struct VersionedGlassModifier<S: Shape>: VersionedViewModifier {

    @usableFromInline
    var glass: VersionedGlass

    @usableFromInline
    var shape: S

    /// Creates a modifier that applies the glass effect in the shape when available,
    /// otherwise applies the `unavailable` content as a background.
    @inlinable
    public init(
        glass: VersionedGlass,
        in shape: S
    ) {
        self.glass = glass
        self.shape = shape
    }

#if XCODE_26 && !os(visionOS)
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
    public func v7Body(content: Content) -> some View {
        content
            .glassEffect(glass.toSwiftUI(), in: shape)
    }
#endif
}

@available(iOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(macOS, introduced: 10.15, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(tvOS, introduced: 13.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
@available(watchOS, introduced: 6.0, deprecated: 26.0, message: "Please use the built in glassEffect(_:in:) with SwiftUI.Glass")
extension View {

    /// Applies the glass effect to a view, in the given shape, when available.
    @_disfavoredOverload
    public func glassEffect<
        S: Shape
    >(
        _ glass: VersionedGlass = .regular,
        in shape: S = VersionedDefaultGlassEffectShape()
    ) -> some View {
        modifier(VersionedGlassModifier(glass: glass, in: shape))
    }
}

// MARK: - Previews

struct GlassModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World")
                .padding()
                .glassEffect(.regular)

            Text("Hello, World")
                .padding()
                .glassEffect(.regular)
                .version(.v1)

            Text("Hello, World")
                .padding()
                .glassEffect(.regular, in: .rect)

            Text("Hello, World")
                .padding()
                .glassEffect(.regular, in: .rect)
                .version(.v1)

#if XCODE_26 && !os(visionOS)
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                Text("Hello, World")
                    .padding()
                    .glassEffect(.regular.interactive())
            }
#endif
        }
    }
}
