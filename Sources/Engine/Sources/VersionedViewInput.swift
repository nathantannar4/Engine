//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

public struct VersionInput: Equatable {

    var rawValue: UInt8

    public static let v1 = VersionInput(rawValue: 1)
    public struct V1: _VersionInput {
        public static let value: VersionInput = .v1
    }

    public static let v2 = VersionInput(rawValue: 2)
    public struct V2: _VersionInput {
        public static let value: VersionInput = .v2
    }

    public static let v3 = VersionInput(rawValue: 3)
    public struct V3: _VersionInput {
        public static let value: VersionInput = .v3
    }

    public static let v4 = VersionInput(rawValue: 4)
    public struct V4: _VersionInput {
        public static let value: VersionInput = .v4
    }

    public static let v5 = VersionInput(rawValue: 5)
    public struct V5: _VersionInput {
        public static let value: VersionInput = .v5
    }
}

public protocol _VersionInput: ViewInput where Key == VersionInputKey { }
extension _VersionInput where Self == VersionInput.V1 {
    public static var v1: VersionInput.V1 { .init() }
}
extension _VersionInput where Self == VersionInput.V2 {
    public static var v2: VersionInput.V2 { .init() }
}
extension _VersionInput where Self == VersionInput.V3 {
    public static var v3: VersionInput.V3 { .init() }
}
extension _VersionInput where Self == VersionInput.V4 {
    public static var v4: VersionInput.V4 { .init() }
}
extension _VersionInput where Self == VersionInput.V5 {
    public static var v5: VersionInput.V5 { .init() }
}

public struct VersionInputKey: ViewInputKey {
    public static var defaultValue: VersionInput {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
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

#if DEBUG
struct UnsupportedVersionView: View {
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
    /// ``VersionedViewModifier`` and ``VersionedDynamicProperty``
    /// On non-debug builds this does nothing
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
    /// ``VersionedViewModifier`` and ``VersionedDynamicProperty``
    /// On non-debug builds this does nothing
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
        var v5Body: some View { Text("V5") }
        var v4Body: some View { Text("V4") }
        var v3Body: some View { Text("V3") }
        var v2Body: some View { Text("V2") }
        var v1Body: some View { Text("V1") }
    }

    struct PreviewVersionInputViewModifier: VersionedViewModifier {
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
            .previewDisplayName("VersionedView")
        }
    }
}
