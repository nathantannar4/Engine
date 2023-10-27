//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Section: MultiView where Parent: View, Content: View, Footer: View {

    public var parent: Parent {
        try! swift_getFieldValue("header", Parent.self, self)
    }

    public var content: Content {
        try! swift_getFieldValue("content", Content.self, self)
    }

    public var footer: Footer {
        try! swift_getFieldValue("footer", Footer.self, self)
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return 3
    }

    public subscript(position: Int) -> Any {
        switch position {
        case 0:
            return parent
        case 1:
            return content
        case 2:
            return footer
        default:
            preconditionFailure("Index out of range")
        }
    }

    public func makeIterator() -> MultiViewSubviewIterator<(Parent, Content, Footer)> {
        MultiViewSubviewIterator(content: (parent, content, footer))
    }
}
