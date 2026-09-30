//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
import Combine
@testable import Engine

/// Tests that values used by SwiftUI to diff views are equal between view updates
@MainActor
final class EqualityTests: XCTestCase {

    // MARK: - Subscript

    func testSubscriptHashable() {
        XCTAssertEqual(Subscript(1), Subscript(1))
        XCTAssertNotEqual(Subscript(1), Subscript(2))
        XCTAssertEqual(Subscript(1).hashValue, Subscript(1).hashValue)
    }

    func testSubscriptEquatable() {
        struct Value: Equatable {
            var id: Int
        }
        XCTAssertEqual(Subscript(Value(id: 1)), Subscript(Value(id: 1)))
        XCTAssertNotEqual(Subscript(Value(id: 1)), Subscript(Value(id: 2)))
        XCTAssertEqual(Subscript(Value(id: 1)).hashValue, Subscript(Value(id: 1)).hashValue)
    }

    func testSubscriptClass() {
        final class Object { }
        let object = Object()
        XCTAssertEqual(Subscript(object), Subscript(object))
        XCTAssertNotEqual(Subscript(object), Subscript(Object()))
        XCTAssertEqual(Subscript(object).hashValue, Subscript(object).hashValue)
    }

    func testSubscriptNonEquatable() {
        struct Value {
            var id: Int
        }
        let value = Subscript(Value(id: 1))
        XCTAssertEqual(value, value)
        XCTAssertNotEqual(Subscript(Value(id: 1)), Subscript(Value(id: 1)))
    }

    func testSubscriptExistential() {
        XCTAssertEqual(Subscript<Any>(1), Subscript<Any>(1))
        XCTAssertNotEqual(Subscript<Any>(1), Subscript<Any>("1"))
        XCTAssertEqual(Subscript<Any>(1).hashValue, Subscript<Any>(1).hashValue)
    }

    func testBindingKeyPathEquality() {
        struct Value: Equatable {
            var id: Int
        }
        // Bindings are compared by their key paths, which are compared by their subscript arguments
        let lhs: WritableKeyPath<Value?, Value> = \.[Subscript(Value(id: 1))]
        let rhs: WritableKeyPath<Value?, Value> = \.[Subscript(Value(id: 1))]
        XCTAssertEqual(lhs, rhs)
        XCTAssertNotEqual(lhs, \.[Subscript(Value(id: 2))])

        let isEqualLHS: WritableKeyPath<Value, Bool> = \.[isEqualTo: Subscript(IsEqualComparison(value: Value(id: 1), defaultValue: Value(id: 0)))]
        let isEqualRHS: WritableKeyPath<Value, Bool> = \.[isEqualTo: Subscript(IsEqualComparison(value: Value(id: 1), defaultValue: Value(id: 0)))]
        XCTAssertEqual(isEqualLHS, isEqualRHS)
    }

    // MARK: - PublishedState

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testPublishedStateDynamicMemberIsReused() {
        struct Item: Equatable {
            var count: Int
            var name: String
        }
        let parent = PublishedState<Item>.PublisherStorage(value: Item(count: 0, name: ""))
        let child = parent[dynamicMember: \.count]
        XCTAssertIdentical(parent[dynamicMember: \.count], child)
        XCTAssertNotIdentical(parent[dynamicMember: \.name] as AnyObject, child)

        // The reused child stays in sync in both directions
        parent.value.count = 1
        XCTAssertEqual(parent[dynamicMember: \.count].value, 1)
        parent[dynamicMember: \.count].value = 2
        XCTAssertEqual(parent.value.count, 2)
    }

    // MARK: - OptionalObservedObject

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testOptionalObservedObjectStorageUpdate() {
        final class Object: ObservableObject { }
        let storage = OptionalObservedObject<Object>.Storage()
        var changes = 0
        let cancellable = storage.objectWillChange.sink { changes += 1 }

        let first = Object()
        storage.update(value: first)
        first.objectWillChange.send()
        XCTAssertEqual(changes, 1)

        // Updating with the same object does not resubscribe
        storage.update(value: first)
        first.objectWillChange.send()
        XCTAssertEqual(changes, 2)

        // Updating with a new object unsubscribes from the previous object
        let second = Object()
        storage.update(value: second)
        first.objectWillChange.send()
        XCTAssertEqual(changes, 2)
        second.objectWillChange.send()
        XCTAssertEqual(changes, 3)

        storage.update(value: nil)
        second.objectWillChange.send()
        XCTAssertEqual(changes, 3)
        XCTAssertNil(storage.value)
        cancellable.cancel()
    }

    // MARK: - ViewStyle

    func testAnyViewStyleEquality() {
        struct EmptyStyle: ViewStyle {
            func makeBody(configuration: Void) -> some View { EmptyView() }
        }
        struct PODStyle: ViewStyle {
            var value: Int
            func makeBody(configuration: Void) -> some View { EmptyView() }
        }
        struct EquatableStyle: ViewStyle, Equatable {
            var value: String
            func makeBody(configuration: Void) -> some View { EmptyView() }
        }
        struct DynamicStyle: ViewStyle {
            @Environment(\.isEnabled) var isEnabled
            func makeBody(configuration: Void) -> some View { EmptyView() }
        }
        XCTAssertEqual(AnyViewStyle(EmptyStyle()), AnyViewStyle(EmptyStyle()))
        XCTAssertEqual(AnyViewStyle(PODStyle(value: 1)), AnyViewStyle(PODStyle(value: 1)))
        XCTAssertNotEqual(AnyViewStyle(PODStyle(value: 1)), AnyViewStyle(PODStyle(value: 2)))
        XCTAssertEqual(AnyViewStyle(EquatableStyle(value: "a")), AnyViewStyle(EquatableStyle(value: "a")))
        XCTAssertNotEqual(AnyViewStyle(EquatableStyle(value: "a")), AnyViewStyle(EquatableStyle(value: "b")))
        XCTAssertNotEqual(AnyViewStyle(EmptyStyle()), AnyViewStyle(PODStyle(value: 0)))
        // Styles that cannot be compared are conservatively not equal
        XCTAssertNotEqual(AnyViewStyle(DynamicStyle()), AnyViewStyle(DynamicStyle()))
        let style = AnyViewStyle(DynamicStyle())
        XCTAssertEqual(style, style)
    }

    // MARK: - Text

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testConcatenatedTextAttributes() {
        let environment = EnvironmentValues()
        let text = (0..<10).reduce(Text("")) { result, index in
            index.isMultiple(of: 2)
                ? result + Text(verbatim: "\(index)")
                : result + Text(verbatim: "\(index)").underline()
        } + (Text(verbatim: "a") + Text(verbatim: "b").strikethrough())

        let nsString = text.resolveNSAttributedString(in: environment)
        XCTAssertEqual(nsString.string, "0123456789ab")
        for index in 0..<10 {
            let underline = nsString.attribute(.underlineStyle, at: index, effectiveRange: nil) as? Int
            XCTAssertEqual(underline, index.isMultiple(of: 2) ? nil : NSUnderlineStyle.single.rawValue, "\(index)")
        }
        XCTAssertNil(nsString.attribute(.strikethroughStyle, at: 10, effectiveRange: nil))
        XCTAssertEqual(nsString.attribute(.strikethroughStyle, at: 11, effectiveRange: nil) as? Int, NSUnderlineStyle.single.rawValue)

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            let attributedString = text.resolveAttributedString(in: environment)
            XCTAssertEqual(String(attributedString.characters), "0123456789ab")
            XCTAssertEqual(attributedString.runs.count, 12)
        }
    }
}
