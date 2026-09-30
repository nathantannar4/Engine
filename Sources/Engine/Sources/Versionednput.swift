//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A version of the SwiftUI runtime, used to select the body of a
/// - ``VersionedView``,
/// - ``VersionedViewModifier``
/// - ``VersionedDynamicProperty``.
/// - ``VersionedToolbarContent``.
public struct VersionInput: Equatable, Sendable {

    var major: UInt8
    var minor: UInt8

    private init(major: UInt8, minor: UInt8 = 0) {
        self.major = major
        self.minor = minor
    }

    /// The version corresponding to the minimum supported OS versions.
    public static let v1 = VersionInput(major: 1)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v1`` version is available.
    public struct V1: _VersionInput {
        public static let value: VersionInput = .v1
    }

    /// The version corresponding to iOS 14, macOS 11, tvOS 14 and watchOS 7 or later.
    public static let v2 = VersionInput(major: 2)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v2`` version is available.
    public struct V2: _VersionInput {
        public static let value: VersionInput = .v2
    }

    /// The version corresponding to iOS 15, macOS 12, tvOS 15 and watchOS 8 or later.
    public static let v3 = VersionInput(major: 3)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v3`` version is available.
    public struct V3: _VersionInput {
        public static let value: VersionInput = .v3
    }

    /// The version corresponding to iOS 16, macOS 13, tvOS 16 and watchOS 9 or later.
    public static let v4 = VersionInput(major: 4)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v4`` version is available.
    public struct V4: _VersionInput {
        public static let value: VersionInput = .v4
    }

    /// The version corresponding to iOS 17, macOS 14, tvOS 17, watchOS 10 and visionOS 1 or later.
    public static let v5 = VersionInput(major: 5)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v5`` version is available.
    public struct V5: _VersionInput {
        public static let value: VersionInput = .v5
    }

    /// The version corresponding to iOS 18, macOS 15, tvOS 18, watchOS 11 and visionOS 2 or later.
    public static let v6 = VersionInput(major: 6)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v6`` version is available.
    public struct V6: _VersionInput {
        public static let value: VersionInput = .v6
    }

    /// The version corresponding to iOS 26, macOS 26, tvOS 26, watchOS 26 and visionOS 26 or later.
    public static let v7 = VersionInput(major: 7)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v7`` version is available.
    public struct V7: _VersionInput {
        public static let value: VersionInput = .v7
    }

    /// The version corresponding to iOS 27, macOS 27, tvOS 27, watchOS 27 and visionOS 27 or later.
    public static let v8 = VersionInput(major: 8)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v8`` version is available.
    public struct V8: _VersionInput {
        public static let value: VersionInput = .v8
    }

    /// The version corresponding to iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1 and visionOS 27.1 or later.
    public static let v8_1 = VersionInput(major: 8, minor: 1)
    /// A ``ViewInputsCondition`` that is `true` when the ``VersionInput/v8_1`` version is available.
    public struct V8_1: _VersionInput {
        public static let value: VersionInput = .v8_1
    }
}

/// A ``ViewInput`` and ``ViewInputsCondition`` for a specific ``VersionInput``.
///
/// On debug builds, the condition is evaluated against the version in the view
/// inputs, which can be overridden with `version(_:)`.
public protocol _VersionInput: ViewInput, ViewInputsCondition where Key == VersionInputKey { }
extension _VersionInput where Self == VersionInput.V1 {
    /// The condition for the ``VersionInput/v1`` version.
    public static var v1: VersionInput.V1 { .init() }
}
extension _VersionInput where Self == VersionInput.V2 {
    /// The condition for the ``VersionInput/v2`` version.
    public static var v2: VersionInput.V2 { .init() }
}
extension _VersionInput where Self == VersionInput.V3 {
    /// The condition for the ``VersionInput/v3`` version.
    public static var v3: VersionInput.V3 { .init() }
}
extension _VersionInput where Self == VersionInput.V4 {
    /// The condition for the ``VersionInput/v4`` version.
    public static var v4: VersionInput.V4 { .init() }
}
extension _VersionInput where Self == VersionInput.V5 {
    /// The condition for the ``VersionInput/v5`` version.
    public static var v5: VersionInput.V5 { .init() }
}
extension _VersionInput where Self == VersionInput.V6 {
    /// The condition for the ``VersionInput/v6`` version.
    public static var v6: VersionInput.V6 { .init() }
}
extension _VersionInput where Self == VersionInput.V7 {
    /// The condition for the ``VersionInput/v7`` version.
    public static var v7: VersionInput.V7 { .init() }
}
extension _VersionInput where Self == VersionInput.V8 {
    /// The condition for the ``VersionInput/v8`` version.
    public static var v8: VersionInput.V8 { .init() }
}
extension _VersionInput where Self == VersionInput.V8_1 {
    /// The condition for the ``VersionInput/v8_1`` version.
    public static var v8_1: VersionInput.V8_1 { .init() }
}

extension _VersionInput {

    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        #if DEBUG
        let version = inputs[VersionInputKey.self]
        #else
        let version = value
        #endif
        return version.isAvailable
    }
}

/// A ``StaticCondition`` that is `true` when a version is available at runtime.
///
/// Unlike ``_VersionInput``, this is not affected by the `version(_:)` modifier.
///
///     StaticConditionalContent(IsVersionAvailable.v8) {
///         Text("v8 Available")
///     } otherwise: {
///         Text("v8 Unavailable")
///     }
///
public struct IsVersionAvailable<Version: _VersionInput>: StaticCondition {
    public static var value: Bool {
        return Version.value.isAvailable
    }
}

extension IsVersionAvailable where Version == VersionInput.V1 {
    /// The condition for the ``VersionInput/v1`` version.
    public static var v1: IsVersionAvailable<VersionInput.V1>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V2 {
    /// The condition for the ``VersionInput/v2`` version.
    public static var v2: IsVersionAvailable<VersionInput.V2>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V3 {
    /// The condition for the ``VersionInput/v3`` version.
    public static var v3: IsVersionAvailable<VersionInput.V3>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V4 {
    /// The condition for the ``VersionInput/v4`` version.
    public static var v4: IsVersionAvailable<VersionInput.V4>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V5 {
    /// The condition for the ``VersionInput/v5`` version.
    public static var v5: IsVersionAvailable<VersionInput.V5>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V6 {
    /// The condition for the ``VersionInput/v6`` version.
    public static var v6: IsVersionAvailable<VersionInput.V6>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V7 {
    /// The condition for the ``VersionInput/v7`` version.
    public static var v7: IsVersionAvailable<VersionInput.V7>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V8 {
    /// The condition for the ``VersionInput/v8`` version.
    public static var v8: IsVersionAvailable<VersionInput.V8>.Type { Self.self }
}
extension IsVersionAvailable where Version == VersionInput.V8_1 {
    /// The condition for the ``VersionInput/v8_1`` version.
    public static var v8_1: IsVersionAvailable<VersionInput.V8_1>.Type { Self.self }
}

/// The ``ViewInputKey`` for the ``VersionInput`` used to select versioned bodies.
///
/// Defaults to the newest version available at runtime.
public struct VersionInputKey: ViewInputKey {
    public static var defaultValue: VersionInput {
        if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
            return .v8_1
        } else if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
            return .v8
        } else if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return .v7
        } else if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return .v6
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            return .v5
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return .v4
        } else if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return .v3
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return .v2
        } else {
            return .v1
        }
    }
}

extension VersionInput {

    /// Returns if the version is currently available
    public var isAvailable: Bool {
        switch self {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return true
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return true
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return true
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return true
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return true
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return true
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return true
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return true
            }
        case .v1:
            return true
        default:
            break
        }
        return false
    }

    /// Returns if the version is currently available and the ``VersionedView`` supports it
    public func isAvailable<Content: VersionedView>(
        _: Content.Type
    ) -> Bool {
        switch self {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return Content.V8_1Body.self != EmptyView.self
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return Content.V8Body.self != EmptyView.self
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return Content.V7Body.self != EmptyView.self
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return Content.V6Body.self != EmptyView.self
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return Content.V5Body.self != EmptyView.self
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return Content.V4Body.self != EmptyView.self
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return Content.V3Body.self != EmptyView.self
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return Content.V2Body.self != EmptyView.self
            }
        case .v1:
            return Content.V1Body.self != EmptyView.self
        default:
            break
        }
        return false
    }

    /// Returns if the version is currently available and the ``VersionedViewModifier`` supports it
    public func isAvailable<Modifier: VersionedViewModifier>(
        _: Modifier.Type
    ) -> Bool {
        switch self {
        case .v8_1:
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return Modifier.V8_1Body.self != Modifier.Content.self
            }
        case .v8:
            if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
                return Modifier.V8Body.self != Modifier.Content.self
            }
        case .v7:
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                return Modifier.V7Body.self != Modifier.Content.self
            }
        case .v6:
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                return Modifier.V6Body.self != Modifier.Content.self
            }
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                return Modifier.V5Body.self != Modifier.Content.self
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return Modifier.V4Body.self != Modifier.Content.self
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                return Modifier.V3Body.self != Modifier.Content.self
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                return Modifier.V2Body.self != Modifier.Content.self
            }
        case .v1:
            return Modifier.V1Body.self != Modifier.Content.self
        default:
            break
        }
        return false
    }
}

#if DEBUG
struct UnavailableVersionedViewBody: View {
    var body: some View {
        VStack {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Image(systemName: "exclamationmark.triangle.fill")
            }

            Text("Unsupported Version")
        }
        .foregroundColor(.red)
    }
}
#endif

#if DEBUG
extension View {

    /// On debug builds, this overrides the version used by ``VersionedView``,
    /// ``VersionedViewModifier`` and ``VersionedDynamicProperty``.
    ///
    /// On non-debug builds this does nothing.
    @inlinable
    public func version<
        Version: _VersionInput
    >(
        _ : Version
    ) -> some View {
        input(Version.self)
    }
}
#else
extension View {

    /// On debug builds, this overrides the version used by ``VersionedView``,
    /// ``VersionedViewModifier`` and ``VersionedDynamicProperty``.
    ///
    /// On non-debug builds this does nothing.
    @inlinable @inline(__always)
    public func version<
        Version: _VersionInput
    >(
        _ : Version
    ) -> Self {
        self
    }
}
#endif

// MARK: - Previews

struct VersionInput_Previews: PreviewProvider {
    struct PreviewVersionInputView: VersionedView {
        var v8_1Body: some View { Text("V8_1") }
        var v8Body: some View { Text("V8") }
        var v7Body: some View { Text("V7") }
        var v6Body: some View { Text("V6") }
        var v5Body: some View { Text("V5") }
        var v4Body: some View { Text("V4") }
        var v3Body: some View { Text("V3") }
        var v2Body: some View { Text("V2") }
        var v1Body: some View { Text("V1") }
    }

    struct PreviewVersionInputViewModifier: VersionedViewModifier {
        func v8_1Body(content: Content) -> some View { Text("V8_1") }
        func v8Body(content: Content) -> some View { Text("V8") }
        func v7Body(content: Content) -> some View { Text("V7") }
        func v6Body(content: Content) -> some View { Text("V6") }
        func v5Body(content: Content) -> some View { Text("V5") }
        func v4Body(content: Content) -> some View { Text("V4") }
        func v3Body(content: Content) -> some View { Text("V3") }
        func v2Body(content: Content) -> some View { Text("V2") }
        func v1Body(content: Content) -> some View { Text("V1") }
    }

    static var previews: some View {
        Group {
            VStack {
                PreviewVersionInputView()
                    .version(.v8_1)

                PreviewVersionInputView()
                    .version(.v8)

                PreviewVersionInputView()
                    .version(.v7)

                PreviewVersionInputView()
                    .version(.v6)

                PreviewVersionInputView()
                    .version(.v5)

                PreviewVersionInputView()
                    .version(.v4)

                PreviewVersionInputView()
                    .version(.v3)

                PreviewVersionInputView()
                    .version(.v2)

                PreviewVersionInputView()
                    .version(.v1)
            }
            .previewDisplayName("VersionedView")

            VStack {
                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v8_1)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v8)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v7)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v6)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v5)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v4)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v3)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v2)

                EmptyView()
                    .modifier(PreviewVersionInputViewModifier())
                    .version(.v1)
            }
            .previewDisplayName("VersionedViewModifier")

            VStack {
                StaticConditionalContent(IsVersionAvailable.v8) {
                    Text("v8 Available")
                } otherwise: {
                    Text("v8 Unavailable")
                }
            }
            .previewDisplayName("StaticConditionalContent")
        }
    }
}
