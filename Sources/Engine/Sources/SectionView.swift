//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// The style for ``SectionView``
public protocol SectionViewStyle: ViewStyle where Configuration == SectionViewStyleConfiguration {
    associatedtype Configuration = Configuration
}

/// The configuration parameters for ``SectionView``
public struct SectionViewStyleConfiguration {

    public struct Header: ViewAlias { }
    public var header: Header { .init() }

    public struct Content: ViewAlias { }
    public var content: Content { .init() }

    public struct Footer: ViewAlias { }
    public var footer: Footer { .init() }
}

/// A container view that you can use to add hierarchy within certain views.
///
/// ``SectionView`` is a re-implementation of SwiftUI's `Section` that is
/// customizable with styles and supports the traits ``IsSectionHeaderTrait``
/// and ``IsSectionFooterTrait``.
@frozen
public struct SectionView<Parent: View, Content: View, Footer: View>: View {

    public var parent: Parent
    public var content: Content
    public var footer: Footer

    public init(parent: Parent, content: Content, footer: Footer) {
        self.parent = parent
        self.content = content
        self.footer = footer
    }

    public init(
        @ViewBuilder content: () -> Content
    ) where Parent == EmptyView, Footer == EmptyView {
        self.init(parent: EmptyView(), content: content(), footer: EmptyView())
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Parent
    ) where Footer == EmptyView {
        self.init(parent: header(), content: content(), footer: EmptyView())
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Parent == EmptyView {
        self.init(parent: EmptyView(), content: content(), footer: footer())
    }

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Parent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(parent: header(), content: content(), footer: footer())
    }

    public var body: some View {
        SectionViewBody(
            configuration: SectionViewStyleConfiguration()
        )
        .viewAlias(SectionViewStyleConfiguration.Header.self) {
            parent.trait(IsSectionHeaderTrait.self, true)
        }
        .viewAlias(SectionViewStyleConfiguration.Content.self) {
            content
        }
        .viewAlias(SectionViewStyleConfiguration.Footer.self) {
            footer.trait(IsSectionFooterTrait.self, true)
        }
    }
}

extension View {

    /// Statically applies the ``SectionViewStyle`` to all descendent ``SectionView``
    /// views in the view hierarchy.
    public func sectionStyle<Style: SectionViewStyle>(_ style: Style) -> some View {
        styledViewStyle(SectionViewBody.self, style: style)
    }
}

/// The default ``SectionViewStyle``
public struct AutomaticSectionStyle: SectionViewStyle {
    public func makeBody(configuration: SectionViewStyleConfiguration) -> some View {
        SwiftUI.Section {
            configuration.content
        } header: {
            configuration.header
        } footer: {
            configuration.footer
        }
    }
}

private struct SectionViewBody: ViewStyledView {
    var configuration: SectionViewStyleConfiguration

    static var defaultStyle: AutomaticSectionStyle {
        AutomaticSectionStyle()
    }
}

extension SectionView: MultiView {
    public func makeSubviewIterator() -> some MultiViewIterator {
        return SwiftUI.Section {
            content
        } header: {
            parent
        } footer: {
            footer
        }
        .makeSubviewIterator()
    }
}

// MARK: - Previews

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                SectionView {
                    Text("Content")
                } header: {
                    Text("Header")
                } footer: {
                    Text("Footer")
                }
            }
        }
    }
}
