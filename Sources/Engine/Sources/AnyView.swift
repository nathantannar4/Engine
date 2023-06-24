//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

extension AnyView {

    /// Creates a type-erased view from a type-erased value if that value is also a `View`
    @_disfavoredOverload
    public init?(_ content: Any) {
        guard let view = AnyView(visiting: content) else {
            return nil
        }
        self = view
    }
}

// MARK: - Previews

struct AnyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AnyView(Optional<String>.none as Any)

            let content: Any = Text("Hello, World")
            AnyView(content)
        }
    }
}
