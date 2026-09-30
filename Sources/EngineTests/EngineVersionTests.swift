//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class VersionTests: XCTestCase {

    let versions: [VersionInput] = [.v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v8_1]

    func testVersionInputEquality() {
        for (index, version) in versions.enumerated() {
            for (otherIndex, other) in versions.enumerated() {
                XCTAssertEqual(version == other, index == otherIndex)
            }
        }
    }

    func testVersionInputAvailability() {
        XCTAssert(VersionInput.v1.isAvailable)
        // Once a version is unavailable, all newer versions must also be unavailable
        let firstUnavailable = versions.firstIndex(where: { !$0.isAvailable }) ?? versions.endIndex
        XCTAssert(versions[firstUnavailable...].allSatisfy { !$0.isAvailable })
        XCTAssert(versions[..<firstUnavailable].allSatisfy { $0.isAvailable })
    }

    func testVersionInputKeyDefaultValue() {
        let defaultValue = VersionInputKey.defaultValue
        XCTAssert(defaultValue.isAvailable)
        // The default is the newest available version
        let newestAvailable = versions.last(where: { $0.isAvailable })
        XCTAssertEqual(defaultValue, newestAvailable)
    }

    func testIsVersionAvailable() {
        XCTAssert(IsVersionAvailable.v1.value)
        XCTAssertEqual(IsVersionAvailable.v2.value, VersionInput.v2.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v3.value, VersionInput.v3.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v4.value, VersionInput.v4.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v5.value, VersionInput.v5.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v6.value, VersionInput.v6.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v7.value, VersionInput.v7.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v8.value, VersionInput.v8.isAvailable)
        XCTAssertEqual(IsVersionAvailable.v8_1.value, VersionInput.v8_1.isAvailable)
        XCTAssertEqual(InvertedStaticCondition<IsVersionAvailable<VersionInput.V1>>.value, false)
    }

    func testVersionInputTypes() {
        XCTAssertEqual(VersionInput.V1.value, .v1)
        XCTAssertEqual(VersionInput.V2.value, .v2)
        XCTAssertEqual(VersionInput.V3.value, .v3)
        XCTAssertEqual(VersionInput.V4.value, .v4)
        XCTAssertEqual(VersionInput.V5.value, .v5)
        XCTAssertEqual(VersionInput.V6.value, .v6)
        XCTAssertEqual(VersionInput.V7.value, .v7)
        XCTAssertEqual(VersionInput.V8.value, .v8)
        XCTAssertEqual(VersionInput.V8_1.value, .v8_1)
    }

    func testVersionedValue() {
        var value = VersionedValue<Int>()
        guard case .unavailable = value else {
            return XCTFail("Expected unavailable")
        }
        value.wrappedValue = 1
        XCTAssertEqual(value.wrappedValue, 1)

        let available = VersionedValue(wrappedValue: "a")
        guard case .available("a") = available else {
            return XCTFail("Expected available")
        }
        XCTAssertEqual(available.wrappedValue, "a")
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testUpdatePhaseValue() {
        var value = UpdatePhase.Value()
        XCTAssertEqual(value.updates, 0)
        let initial = value

        value.update()
        XCTAssertEqual(value.updates, 1)
        XCTAssertNotEqual(value, initial)

        // Overflow wraps rather than trapping
        value.phase = .max
        value.update()
        XCTAssertEqual(value.updates, 0)
        XCTAssertEqual(value, initial)
    }
}
