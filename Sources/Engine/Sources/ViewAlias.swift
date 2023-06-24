//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that is an alias for another view that's statically defined by an ancestor.
///
/// A ``ViewAlias`` is can be defined statically by one of its ancestors.
/// Because ``ViewAlias`` is guaranteed to be static it can be used for
/// type-erasure without the performance impacts associated with `AnyView`.
/// Use the ``View/viewAlias(_:source:)`` on an ancestor to define
/// the view ``ViewAlias`` should be resolved to.
///
/// For example, ``ViewAlias`` can be used for "dependency-injection".
/// Such as the case when creating a ``ViewStyle``.
///
///     struct RowConfiguration {
///         var label: LocalizedStringKey
///
///         struct Content: ViewAlias { }
///         var content: Content { .init() }
///     }
///
///     struct RowView: View {
///         var configuration: RowConfiguration
///
///         var body: some View {
///             HStack {
///                 Text(configuration.label)
///
///                 configuration.content
///             }
///         }
///     }
///
///     var body: some View {
///         RowView(configuration: .init(label: "Label"))
///             .viewAlias(RowConfiguration.Content.self) {
///                 Text("Content")
///             }
///     }
///
/// If a ``ViewAlias`` is not defined by one of its ancestors, its `body`
/// will be resolved to an `EmptyView`. If you would like a different fallback,
/// you can implement the optional `defaultBody`.
///
public typealias ViewAlias = EngineCore.ViewAlias

extension View {

    /// Statically type-erases `Source` to be resolved by the ``ViewAlias``.
    @inlinable
    public func viewAlias<
        Alias: ViewAlias,
        Source: View
    >(
        _ : Alias.Type,
        @ViewBuilder source: () -> Source
    ) -> some View {
        modifier(
            ViewAliasSourceModifier(
                Alias.self,
                source: source()
            )
        )
    }
}

// MARK: - Previews

struct PreviewAlias: ViewAlias {
    var defaultBody: some View {
        Text("Default")
    }
}

struct ViewAlias_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                VStack {
                    PreviewAlias()

                    PreviewAlias()
                }
                .viewAlias(PreviewAlias.self) {
                    Text("Hello, World")
                }
            }
            .previewDisplayName("Text")

            ZStack {
                VStack {
                    PreviewAlias()
                }
                .viewAlias(PreviewAlias.self) {
                    ForEach(0...2, id: \.self) { index in
                        Text(index.description)
                    }
                }
            }
            .previewDisplayName("ForEach")

            ZStack {
                PreviewAlias()
            }
            .previewDisplayName("DefaultBody")
        }
    }
}
