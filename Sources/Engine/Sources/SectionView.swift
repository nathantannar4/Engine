//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A wrapper view that adds the ``IsSectionHeaderTrait`` trait.
///
/// Use within the header of a `Section` so that the header can be identified
/// when the section is transformed by a ``VariadicViewAdapter``.
@frozen
public struct SectionHeader<Content: View>: View {

    /// The wrapped content.
    public var content: Content

    /// Creates a wrapper view with the given content.
    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        UnaryViewAdaptor {
            content
        }
        .trait(IsSectionHeaderTrait.self, true)
    }
}

/// A wrapper view that adds the ``IsSectionFooterTrait`` trait.
///
/// Use within the footer of a `Section` so that the footer can be identified
/// when the section is transformed by a ``VariadicViewAdapter``.
@frozen
public struct SectionFooter<Content: View>: View {

    /// The wrapped content.
    public var content: Content

    /// Creates a wrapper view with the given content.
    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        UnaryViewAdaptor {
            content
        }
        .trait(IsSectionFooterTrait.self, true)
    }
}

// MARK: - Previews

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Section {
                    Text("Content")
                } header: {
                    SectionHeader {
                        Text("Header")
                    }
                } footer: {
                    SectionFooter {
                        Text("Footer")
                    }
                }

                VariadicViewAdapter {
                    Section {
                        Text("Content")
                    } header: {
                        SectionHeader {
                            Text("Header")
                        }
                    } footer: {
                        SectionFooter {
                            Text("Footer")
                        }
                    }
                } content: { sourceView in
                    ForEach(sourceView.sections) { section in
                        VStack {
                            section.header
                                .border(Color.red)

                            section.content
                                .border(Color.blue)

                            section.footer
                                .border(Color.yellow)
                        }
                    }
                }

            }
        }
    }
}
