//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

@MainActor
final class CoreTypeIdentifierTests: XCTestCase {

    func testTypeIdentifier() {
        XCTAssertEqual(TypeIdentifier(Int.self), TypeIdentifier(Int.self))
        XCTAssertNotEqual(TypeIdentifier(Int.self), TypeIdentifier(String.self))
        XCTAssertNotEqual(TypeIdentifier(Int.self), TypeIdentifier(Int?.self))
        XCTAssertEqual(TypeIdentifier(Array<Int>.self), TypeIdentifier([Int].self))
        XCTAssertEqual(Set([TypeIdentifier(Int.self), TypeIdentifier(Int.self), TypeIdentifier(String.self)]).count, 2)

        XCTAssertEqual(TypeIdentifier(Int.self).debugDescription, "Int")
        XCTAssertEqual(TypeIdentifier(Text.self).debugDescription, "Text")
        XCTAssertEqual(TypeIdentifier(Optional<Text>.self).debugDescription, "Optional<Text>")
    }

    func testViewTypeIdentifier() {
        let root = ViewTypeIdentifier(Text.self)
        XCTAssertEqual(root, ViewTypeIdentifier(Text.self))
        XCTAssertNotEqual(root, ViewTypeIdentifier(EmptyView.self))
        XCTAssertEqual(root.debugDescription, "Text")

        let subview = root.appending(EmptyView.self)
        XCTAssertEqual(subview, ViewTypeIdentifier(Text.self).appending(EmptyView.self))
        XCTAssertNotEqual(subview, root)
        XCTAssertEqual(subview.debugDescription, "Text->EmptyView")

        let offset = subview.appending(offset: 1)
        XCTAssertEqual(offset, subview.appending(offset: 1))
        XCTAssertNotEqual(offset, subview.appending(offset: 2))
        XCTAssertNotEqual(offset, subview.appending(offset: "1"))
        XCTAssertEqual(offset.debugDescription, "Text->EmptyView->" + AnyHashable(1).debugDescription)

        var mutated = root
        mutated.append(EmptyView.self)
        XCTAssertEqual(mutated, subview)
        mutated.append(offset: 1)
        XCTAssertEqual(mutated, offset)

        // Order matters
        XCTAssertNotEqual(
            ViewTypeIdentifier(Text.self).appending(EmptyView.self).appending(Color.self),
            ViewTypeIdentifier(Text.self).appending(Color.self).appending(EmptyView.self)
        )
    }
}
