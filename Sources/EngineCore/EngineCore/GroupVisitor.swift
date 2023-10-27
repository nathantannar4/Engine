//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group: MultiView where Content: View & MultiView {

    public var content: Content {
        try! swift_getFieldValue("content", Content.self, self)
    }

    public var startIndex: Content.Index {
        content.startIndex
    }

    public var endIndex: Content.Index {
        content.endIndex
    }

    public subscript(position: Content.Index) -> Content.Subview {
        content[position]
    }

    public func makeIterator() -> Content.Iterator {
        content.makeIterator()
    }
}

/*
private struct GroupStartIndexVisitor<Content: View>: ViewVisitor {
    var content: Content
    var startIndex: Int!

    mutating func visit<Content: View>(type: Content.Type) {
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            var visitor = MultiViewStartIndexVisitor<Int>()
            conformance.visit(content: content, visitor: &visitor)
            startIndex = visitor.startIndex
        } else {
            startIndex = 0
        }
    }
}

private struct GroupEndIndexVisitor<Content: View>: ViewVisitor {
    var content: Content
    var endIndex: Int!

    mutating func visit<Content: View>(type: Content.Type) {
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            var visitor = MultiViewEndIndexVisitor<Int>()
            conformance.visit(content: content, visitor: &visitor)
            endIndex = visitor.endIndex
        } else {
            endIndex = 1
        }
    }
}

private struct GroupSubviewVisitor<Content: View>: ViewVisitor {
    var position: Int
    var content: Content
    var subview: Any!

    mutating func visit<Content: View>(type: Content.Type) {
        if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            var visitor = MultiViewSubviewVisitor<Int, Any>(position: position)
            conformance.visit(content: content, visitor: &visitor)
            subview = visitor.subview
        } else {
            subview = content
        }
    }
}
*/
