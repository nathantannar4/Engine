//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view that displays the `source` text scaled by the same factor as the
/// `reference` text, such as when the text shrinks with `minimumScaleFactor(_:)`.
///
/// Use this to keep multiple texts at a consistent size when one of them must
/// scale down to fit the available space.
@frozen
public struct SymmetricallyScaledText: View {

    @usableFromInline
    var source: Text
    @usableFromInline
    var reference: Text

    /// Creates a view that displays `source` scaled symmetrically to `reference`.
    @inlinable
    public init(source: Text, reference: Text) {
        self.source = source
        self.reference = reference
    }

    /// Creates a view that displays localized `source` text scaled symmetrically to `reference`.
    @inlinable
    public init(source: LocalizedStringKey, reference: LocalizedStringKey) {
        self.init(source: Text(source), reference: Text(reference))
    }

    /// Creates a view that displays `source` scaled symmetrically to `reference`.
    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(source: S, reference: S) {
        self.init(source: Text(source), reference: Text(reference))
    }

    public var body: some View {
        _SymmetricallyScaledText(source: source, reference: reference)
    }
}

/// A view that displays the `source` text scaled by the same factor as the
/// longest of the `references`.
///
/// The longest reference is determined by the number of characters of each
/// resolved text. When `references` is empty, `source` is used as the reference.
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct SymmetricallyScaledReferencesText: View {

    @usableFromInline
    var source: Text
    @usableFromInline
    var references: [Text]

    /// Creates a view that displays `source` scaled symmetrically to the longest of `references`.
    @inlinable
    public init(source: Text, references: [Text]) {
        self.source = source
        self.references = references
    }

    /// Creates a view that displays `source` scaled symmetrically to the longest of `references`.
    @inlinable
    public init(source: Text, @TextBuilder references: () -> [Text]) {
        self.init(source: source, references: references())
    }

    public var body: some View {
        EquatableBody(source: source, references: references)
            .equatable()
    }

    private struct EquatableBody: View, Equatable {

        var source: Text
        var references: [Text]

        var body: some View {
            ResolvedBody(source: source, references: references)
        }

        private struct ResolvedBody: View {

            var source: Text
            var references: [Text]

            @Environment(\.self) var environment

            var reference: Text {
                let longestReference = references
                    .map({ $0.resolve(in: environment) })
                    .sorted(by: { $0.count > $1.count })
                    .first
                return Text(longestReference) ?? source
            }

            var body: some View {
                SymmetricallyScaledText(source: source, reference: reference)
            }
        }
    }
}

// MARK: - Previews

struct SymmetricallyScaledText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let topText = Text("Hello, World")
            let bottomText = Text("Lorem ipsum dolor sit amet consectetur adipiscing elit")
            VStack {
                topText
                bottomText
            }

            VStack {
                SymmetricallyScaledText(
                    source: topText,
                    reference: bottomText
                )

                SymmetricallyScaledText(
                    source: bottomText,
                    reference: topText
                )

                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    SymmetricallyScaledReferencesText(
                        source: topText
                    ) {
                        topText
                        bottomText
                    }

                    SymmetricallyScaledReferencesText(
                        source: bottomText
                    ) {
                        topText
                        bottomText
                    }
                }
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(width: 200)
        }
    }
}
