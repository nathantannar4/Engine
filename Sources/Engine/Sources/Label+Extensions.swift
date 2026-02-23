//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Label {

    public var title: Title {
        try! swift_getFieldValue("title", Title.self, self)
    }

    public var icon: Icon {
        try! swift_getFieldValue("icon", Icon.self, self)
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct Label_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let label = Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
            }

            label

            label.title

            label.icon
        }
    }
}
