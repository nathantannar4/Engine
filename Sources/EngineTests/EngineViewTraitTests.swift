//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class ViewTraitTests: XCTestCase {

    func testZIndex() {
        XCTAssertNotNil(ZIndexTrait.conformance)
    }

    func testLayoutPriority() {
        XCTAssertNotNil(LayoutPriorityTrait.conformance)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testTag() {
        XCTAssertNotNil(TagValueTrait<Int>.conformance)
    }

    func testIsSectionHeader() {
        XCTAssertNotNil(IsSectionHeaderTrait.conformance)
    }

    func testIsSectionFooter() {
        XCTAssertNotNil(IsSectionFooterTrait.conformance)
    }
}
