//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class UtilityTests: XCTestCase {

    func testTransaction() {
        let transaction = Transaction()
        XCTAssertFalse(transaction.isAnimated)
        XCTAssertFalse(transaction.disablesAnimations)

        let animated = transaction.animation(.default)
        XCTAssert(animated.isAnimated)
        XCTAssertFalse(transaction.isAnimated)
        XCTAssertFalse(animated.animation(nil).isAnimated)

        XCTAssert(transaction.disablesAnimations().disablesAnimations)
        XCTAssertFalse(transaction.disablesAnimations().disablesAnimations(false).disablesAnimations)

        XCTAssert(Transaction(animation: .linear).isAnimated)
    }

    func testOptionalTransaction() {
        XCTAssertFalse(Optional<Transaction>.none.isAnimated)
        XCTAssertFalse(Optional(Transaction()).isAnimated)
        XCTAssert(Optional(Transaction(animation: .default)).isAnimated)
    }

    func testWithCATransaction() {
        let expectation = expectation(description: "completion")
        withCATransaction {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    final class Observer: DeallocationObserver {
        var count = 0

        func didDeinit() {
            count += 1
        }
    }

    func testDeallocationTracker() {
        final class Object { }

        let observer = Observer()
        let removedObserver = Observer()
        var object: Object? = Object()
        do {
            // The tracker must not outlive this scope, or it won't deinit with the object
            let tracker = DeallocationTracker.shared(for: object!)
            XCTAssert(tracker === DeallocationTracker.shared(for: object!))
            XCTAssertFalse(tracker === DeallocationTracker.shared(for: Object()))

            tracker.addObserver(observer)
            tracker.addObserver(removedObserver)
            tracker.removeObserver(removedObserver)
        }
        XCTAssertEqual(observer.count, 0)

        object = nil
        XCTAssertEqual(observer.count, 1)
        XCTAssertEqual(removedObserver.count, 0)
    }

    func testDeallocationTrackerWeaklyHoldsObservers() {
        final class Object { }

        let object = Object()
        weak var weakObserver: Observer?
        do {
            let observer = Observer()
            weakObserver = observer
            DeallocationTracker.shared(for: object).addObserver(observer)
        }
        XCTAssertNil(weakObserver)
    }
}
