//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group: MultiView where Content: View {

    public var content: Content {
        try! swift_getFieldValue("content", Content.self, self)
    }

    public func makeSubviewIterator() -> some MultiViewIterator {
        content.makeSubviewIterator()
    }
}
