//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
import Combine
@testable import Engine

@MainActor
final class StateTests: XCTestCase {

    func testPublishedState() {
        let state = PublishedState(wrappedValue: 1)
        XCTAssertEqual(state.wrappedValue, 1)
        state.wrappedValue = 2
        XCTAssertEqual(state.wrappedValue, 2)

        let binding = state.projectedValue
        XCTAssertEqual(binding.wrappedValue, 2)
        binding.wrappedValue = 3
        XCTAssertEqual(state.wrappedValue, 3)

        binding.projectedValue.wrappedValue = 4
        XCTAssertEqual(state.wrappedValue, 4)
    }

    func testPublishedStatePublisher() {
        let state = PublishedState(wrappedValue: 1)
        var values: [Int] = []
        let cancellable = state.projectedValue.publisher.sink { values.append($0) }
        state.wrappedValue = 2
        state.projectedValue.wrappedValue = 3
        XCTAssertEqual(values, [1, 2, 3])
        cancellable.cancel()
    }

    func testPublishedStateConstantBinding() {
        let binding = PublishedState<Int>.Binding.constant(1)
        XCTAssertEqual(binding.wrappedValue, 1)
        // Writes to a constant are ignored
        binding.wrappedValue = 2
        XCTAssertEqual(binding.wrappedValue, 1)
        binding.projectedValue.wrappedValue = 2
        XCTAssertEqual(binding.projectedValue.wrappedValue, 1)

        var values: [Int] = []
        let cancellable = binding.publisher.sink { values.append($0) }
        XCTAssertEqual(values, [1])
        cancellable.cancel()
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testPublishedStateDynamicMember() {
        struct Item: Equatable {
            var name: String
            var count: Int
        }
        let state = PublishedState(wrappedValue: Item(name: "a", count: 0))
        let count = state.projectedValue.count
        XCTAssertEqual(count.wrappedValue, 0)

        // Parent changes propagate to the child
        state.wrappedValue.count = 1
        XCTAssertEqual(count.wrappedValue, 1)

        // Child changes propagate to the parent
        count.wrappedValue = 2
        XCTAssertEqual(state.wrappedValue, Item(name: "a", count: 2))

        // Unrelated changes are not lost
        state.wrappedValue.name = "b"
        XCTAssertEqual(count.wrappedValue, 2)
        XCTAssertEqual(state.wrappedValue, Item(name: "b", count: 2))

        let constant = PublishedState<Item>.Binding.constant(Item(name: "c", count: 5)).count
        XCTAssertEqual(constant.wrappedValue, 5)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testPublishedStateDynamicMemberDoesNotLeak() {
        struct Item: Equatable {
            var count: Int
        }
        func cancellables(_ storage: AnyObject) -> Int? {
            Mirror(reflecting: storage).children
                .first(where: { $0.label == "cancellables" })
                .flatMap { ($0.value as? Set<AnyCancellable>)?.count }
        }

        let parent = PublishedState<Item>.PublisherStorage(value: Item(count: 0))
        XCTAssertEqual(cancellables(parent), 0)

        weak var weakChild: PublishedState<Int>.PublisherStorage?
        do {
            // Simulates `$state.count` being accessed on every view update
            for _ in 0..<10 {
                let child = parent[dynamicMember: \.count]
                weakChild = child
                XCTAssertEqual(cancellables(child), 2)
            }
        }
        XCTAssertNil(weakChild)
        XCTAssertEqual(cancellables(parent), 0)

        // Parent changes after a child is released are safe
        parent.value.count = 1
        XCTAssertEqual(parent.value.count, 1)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testPublishedStateDynamicMemberDoesNotWriteBack() {
        struct Item: Equatable {
            var count: Int
        }
        let parent = PublishedState<Item>.PublisherStorage(value: Item(count: 0))
        let child = parent[dynamicMember: \.count]

        var parentChanges = 0
        let cancellable = parent.objectWillChange.sink { parentChanges += 1 }

        // A parent change is not echoed back from the child as a second change
        parent.value.count = 1
        XCTAssertEqual(child.value, 1)
        XCTAssertEqual(parentChanges, 1)

        child.value = 2
        XCTAssertEqual(parent.value.count, 2)
        XCTAssertEqual(parentChanges, 2)
        cancellable.cancel()
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testFormatTransform() throws {
        let transform = FormatTransform(format: IntegerFormatStyle<Int>().grouping(.never))
        XCTAssertEqual(transform.get(1000), "1000")
        XCTAssertEqual(try transform.set("42"), 42)
        XCTAssertThrowsError(try transform.set("abc"))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testOptionalFormatTransform() throws {
        let transform = OptionalFormatTransform(format: IntegerFormatStyle<Int>().grouping(.never), defaultValue: "-")
        XCTAssertEqual(transform.get(nil), "-")
        XCTAssertEqual(transform.get(7), "7")
        XCTAssertEqual(try transform.set("42"), 42)
        XCTAssertThrowsError(try transform.set("abc"))
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testColorMatrix() {
        let keyPaths: [WritableKeyPath<Engine.ColorMatrix, Float>] = [
            \.r1, \.r2, \.r3, \.r4, \.r5,
            \.g1, \.g2, \.g3, \.g4, \.g5,
            \.b1, \.b2, \.b3, \.b4, \.b5,
            \.a1, \.a2, \.a3, \.a4, \.a5,
        ]
        let identity = Engine.ColorMatrix()
        var matrix = Engine.ColorMatrix()
        for (index, keyPath) in keyPaths.enumerated() {
            matrix[keyPath: keyPath] = Float(index + 1)
        }
        // Each component is stored independently
        for (index, keyPath) in keyPaths.enumerated() {
            XCTAssertEqual(matrix[keyPath: keyPath], Float(index + 1))
        }
        XCTAssertNotEqual(matrix, identity)
        XCTAssertEqual(identity * matrix, matrix)
        XCTAssertEqual(matrix * identity, matrix)
    }

    func testViewModifierBuilder() {
        struct M0: ViewModifier {
            func body(content: Content) -> some View { content }
        }
        struct M1: ViewModifier {
            func body(content: Content) -> some View { content }
        }

        @ViewModifierBuilder
        func empty() -> some ViewModifier { }
        XCTAssert(type(of: empty()) == EmptyModifier.self)

        @ViewModifierBuilder
        func single() -> some ViewModifier { M0() }
        XCTAssert(type(of: single()) == M0.self)

        @ViewModifierBuilder
        func pair() -> some ViewModifier {
            M0()
            M1()
        }
        XCTAssert(type(of: pair()) == ModifiedContent<M0, M1>.self)

        @ViewModifierBuilder
        func five() -> some ViewModifier {
            M0()
            M1()
            M0()
            M1()
            M0()
        }
        XCTAssert(
            type(of: five()) == ModifiedContent<ModifiedContent<ModifiedContent<ModifiedContent<M0, M1>, M0>, M1>, M0>.self
        )

        let view = EmptyView().modifier { M0() }
        XCTAssert(type(of: view) == ModifiedContent<EmptyView, M0>.self)
    }
}
