//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group where Content: View {

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in Group(subviewsOf: ...) init")
    public init<V: View, Result: View>(
        subviewsOf view: V,
        @ViewBuilder transform: @escaping (VariadicView<V>) -> Result
    ) where Content == VariadicViewAdapter<V, Result> {
        self.init {
            VariadicViewAdapter(source: view, content: transform)
        }
    }
}


// MARK: - Previews

struct Group_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group(subviewsOf: Content()) { source in
                VStack {
                    HStack {
                        source[0]
                        source[1]
                    }

                    source[2...]
                }
            }
            .previewDisplayName("subviewsOf")
        }
    }

    struct Content: View {
        var body: some View {
            Section {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
                Text("Line 4")
                Text("Line 5")
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
        }
    }
}
