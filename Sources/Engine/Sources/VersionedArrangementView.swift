//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct VersionedArrangementView<
    PrimaryContent: View,
    SecondaryContent: View,
    UnavailableContent: View
>: VersionedView {

    public var primary: PrimaryContent
    public var secondary: SecondaryContent
    public var content: UnavailableContent

    @inlinable
    public init(
        @ViewBuilder primary: () -> PrimaryContent,
        @ViewBuilder secondary: () -> SecondaryContent,
        @ViewBuilder unavailable: (PrimaryContent, SecondaryContent) -> UnavailableContent,
    ) {
        let primary = primary()
        let secondary = secondary()
        self.primary = primary
        self.secondary = secondary
        self.content = unavailable(primary, secondary)
    }

    @inlinable
    public init(
        @ViewBuilder primary: () -> PrimaryContent,
        @ViewBuilder secondary: () -> SecondaryContent
    ) where UnavailableContent == VersionedArrangementViewDefaultUnavailableBody<PrimaryContent, SecondaryContent> {
        self.init(primary: primary, secondary: secondary) { primary, secondary in
            VersionedArrangementViewDefaultUnavailableBody(primary: primary, secondary: secondary)
        }
    }

    #if XCODE_27_1
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    public var v8_1Body: some View {
        _V8_1Body(primary: primary, secondary: secondary)
    }

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    private struct _V8_1Body: View {
        var primary: PrimaryContent
        var secondary: SecondaryContent

        var body: some View {
            ArrangementView {
                primary
            } secondary: {
                secondary
            }
        }
    }
    #endif

    public var v1Body: some View {
        content
    }
}

@frozen
public struct VersionedArrangementViewDefaultUnavailableBody<
    PrimaryContent: View,
    SecondaryContent: View
>: VersionedView {

    public var primary: PrimaryContent
    public var secondary: SecondaryContent

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @inlinable
    public init(primary: PrimaryContent, secondary: SecondaryContent) {
        self.primary = primary
        self.secondary = secondary
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        LayoutAdapter {
            if verticalSizeClass == .regular || horizontalSizeClass == .compact {
                VStackLayout(spacing: 0)
            } else {
                HStackLayout(spacing: 0)
            }
        } content: {
            content
        }
    }

    public var v1Body: some View {
        VStack(spacing: 0) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        primary
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        secondary
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Previews

struct VersionedArrangementView_Previews: PreviewProvider {
    static var previews: some View {
        VersionedArrangementView {
            ZStack {
                Color.blue.opacity(0.3).ignoresSafeArea()

                Color.blue.opacity(0.3)

                Text("Primary")
            }
        } secondary: {
            ZStack {
                Color.red.opacity(0.3).ignoresSafeArea()

                Color.red.opacity(0.3)

                Text("Secondary")
            }
        }

        VersionedArrangementView {
            Text("Primary")
        } secondary: {
            Text("Secondary")
        } unavailable: { primary, secondary in
            VStack {
                primary
                secondary
            }
        }
    }
}
