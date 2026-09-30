//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct ViewModifierContentAlias: ViewAlias { }

/// Use this to define an inline modifier without declaring a dedicated
/// `ViewModifier` type.
///
/// ```
/// Text("Hello, World")
///     .modifier { content in
///         content
///             .background(Color.red)
///     }
/// ```
@frozen
public struct ViewModifierAdapter<ModifiedBody: View>: ViewModifier {

    @usableFromInline
    var content: ModifiedBody

    /// Creates a modifier from the result of `content`, which is passed
    /// an alias for the content being modified.
    public init(
        @ViewBuilder content: (ViewModifierContentAlias) -> ModifiedBody
    ) {
        self.content = content(ViewModifierContentAlias())
    }

    public func body(content: Content) -> some View {
        self.content
            .viewAlias(ViewModifierContentAlias.self) {
                content
            }
    }
}

extension View {

    /// Applies an inline modifier to the view, where `content` is passed an
    /// alias for this view.
    public func modifier<ModifiedBody: View>(
        @ViewBuilder content: (ViewModifierContentAlias) -> ModifiedBody
    ) -> some View {
        modifier(ViewModifierAdapter(content: content))
    }
}

// MARK: - Previews

struct ViewModifierAdapter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier { content in
                    content
                        .background(Color.red)
                }
        }
    }
}
