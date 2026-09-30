//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class BindingTests: XCTestCase {

    final class Box<Value>: @unchecked Sendable {
        var value: Value

        init(_ value: Value) {
            self.value = value
        }

        var binding: Binding<Value> {
            Binding(get: { self.value }, set: { self.value = $0 })
        }
    }

    func testNilLiteral() {
        let binding: Binding<Int?> = nil
        XCTAssertNil(binding.wrappedValue)
    }

    func testIsNil() {
        let box = Box<Int?>(1)
        let isNil = box.binding.isNil()
        let isNotNil = box.binding.isNotNil()
        XCTAssertFalse(isNil.wrappedValue)
        XCTAssert(isNotNil.wrappedValue)

        // Setting `isNil` to false cannot produce a value
        isNil.wrappedValue = false
        XCTAssertEqual(box.value, 1)
        isNotNil.wrappedValue = true
        XCTAssertEqual(box.value, 1)

        isNil.wrappedValue = true
        XCTAssertNil(box.value)
        XCTAssert(isNil.wrappedValue)

        box.value = 2
        isNotNil.wrappedValue = false
        XCTAssertNil(box.value)
    }

    func testAsOptional() {
        let box = Box(1)
        let optional = box.binding.asOptional()
        XCTAssertEqual(optional.wrappedValue, 1)
        optional.wrappedValue = 2
        XCTAssertEqual(box.value, 2)
        // Setting `nil` is ignored
        optional.wrappedValue = nil
        XCTAssertEqual(box.value, 2)
    }

    func testUnwrapping() throws {
        let box = Box<Int?>(nil)
        XCTAssertNil(Binding(unwrapping: box.binding))

        box.value = 1
        let unwrapped = try XCTUnwrap(Binding(unwrapping: box.binding))
        XCTAssertEqual(unwrapped.wrappedValue, 1)
        unwrapped.wrappedValue = 2
        XCTAssertEqual(box.value, 2)

        box.value = nil
        let defaulted = Binding(unwrapping: box.binding, defaultValue: 5)
        XCTAssertEqual(defaulted.wrappedValue, 5)
        defaulted.wrappedValue = 3
        XCTAssertEqual(box.value, 3)

        box.value = nil
        XCTAssertEqual(box.binding.unwrap(defaultValue: 7).wrappedValue, 7)
        XCTAssertEqual(box.binding[default: 8].wrappedValue, 8)
        box.binding[default: 8].wrappedValue = 9
        XCTAssertEqual(box.value, 9)
    }

    func testUnwrappingNonHashable() throws {
        struct Value: Equatable {
            var id: Int
        }
        let box = Box<Value?>(nil)
        XCTAssertNil(Binding(unwrapping: box.binding))
        XCTAssertEqual(box.binding.unwrap(defaultValue: Value(id: 1)).wrappedValue, Value(id: 1))
        XCTAssertEqual(box.binding[default: Value(id: 2)].wrappedValue, Value(id: 2))

        box.binding.unwrap(defaultValue: Value(id: 1)).wrappedValue = Value(id: 3)
        XCTAssertEqual(box.value, Value(id: 3))

        let unwrapped = try XCTUnwrap(Binding(unwrapping: box.binding))
        unwrapped.wrappedValue.id = 4
        XCTAssertEqual(box.value, Value(id: 4))
    }

    func testStringValue() {
        let box = Box<String?>(nil)
        let value = box.binding.value()
        XCTAssertEqual(value.wrappedValue, "")
        value.wrappedValue = "Hello"
        XCTAssertEqual(box.value, "Hello")
        value.wrappedValue = ""
        XCTAssertNil(box.value)

        let defaulted = box.binding.value(defaultValue: "Default")
        XCTAssertEqual(defaulted.wrappedValue, "Default")
        defaulted.wrappedValue = ""
        XCTAssertEqual(box.value, "")
    }

    func testIntValue() {
        let box = Box<Int?>(nil)
        let value = box.binding.value()
        XCTAssertEqual(value.wrappedValue, "")
        value.wrappedValue = "42"
        XCTAssertEqual(box.value, 42)
        XCTAssertEqual(value.wrappedValue, "42")
        value.wrappedValue = "abc"
        XCTAssertNil(box.value)
        value.wrappedValue = "1"
        value.wrappedValue = ""
        XCTAssertNil(box.value)

        let defaulted = box.binding.value(defaultValue: "0")
        XCTAssertEqual(defaulted.wrappedValue, "0")
        defaulted.wrappedValue = "7"
        XCTAssertEqual(box.value, 7)
    }

    func testDoubleValue() {
        let box = Box<Double?>(nil)
        let value = box.binding.value()
        XCTAssertEqual(value.wrappedValue, "")
        value.wrappedValue = "1.5"
        XCTAssertEqual(box.value, 1.5)
        XCTAssertEqual(value.wrappedValue, "1.5")
        value.wrappedValue = "abc"
        XCTAssertNil(box.value)
        XCTAssertEqual(box.binding.value(defaultValue: "none").wrappedValue, "none")
    }

    func testFloatValue() {
        let box = Box<Float?>(nil)
        let value = box.binding.value()
        XCTAssertEqual(value.wrappedValue, "")
        value.wrappedValue = "2.5"
        XCTAssertEqual(box.value, 2.5)
        XCTAssertEqual(value.wrappedValue, "2.5")
        value.wrappedValue = ""
        XCTAssertNil(box.value)
        XCTAssertEqual(box.binding.value(defaultValue: "none").wrappedValue, "none")
    }

    func testURLValue() {
        let box = Box<URL?>(nil)
        let value = box.binding.value()
        XCTAssertEqual(value.wrappedValue, "")
        value.wrappedValue = "https://example.com"
        XCTAssertEqual(box.value, URL(string: "https://example.com"))
        XCTAssertEqual(value.wrappedValue, "https://example.com")
        XCTAssertEqual(Box<URL?>(nil).binding.value(defaultValue: "none").wrappedValue, "none")
    }

    func testBoolValue() {
        let box = Box<Bool?>(nil)
        let isTrue = box.binding.isTrue()
        let isFalse = box.binding.isFalse()
        XCTAssertFalse(isTrue.wrappedValue)
        XCTAssertFalse(isFalse.wrappedValue)

        isTrue.wrappedValue = true
        XCTAssertEqual(box.value, true)
        XCTAssert(isTrue.wrappedValue)
        XCTAssertFalse(isFalse.wrappedValue)

        isFalse.wrappedValue = true
        XCTAssertEqual(box.value, false)
        XCTAssertFalse(isTrue.wrappedValue)
        XCTAssert(isFalse.wrappedValue)
    }

    func testInverted() {
        let box = Box(false)
        let inverted = !box.binding
        XCTAssert(inverted.wrappedValue)
        inverted.wrappedValue = false
        XCTAssert(box.value)

        box.binding.toggle()
        XCTAssertFalse(box.value)
    }

    func testSetContains() {
        let box = Box<Set<Int>>([1])
        let contains = box.binding.contains(2)
        XCTAssertFalse(contains.wrappedValue)
        contains.wrappedValue = true
        XCTAssertEqual(box.value, [1, 2])
        XCTAssert(contains.wrappedValue)
        contains.wrappedValue = false
        XCTAssertEqual(box.value, [1])
    }

    func testCollectionContains() {
        let box = Box([1, 2])
        let contains = box.binding.contains(3)
        XCTAssertFalse(contains.wrappedValue)
        contains.wrappedValue = true
        XCTAssertEqual(box.value, [1, 2, 3])
        // Inserting an existing element does not duplicate it
        contains.wrappedValue = true
        XCTAssertEqual(box.value, [1, 2, 3])
        box.binding.contains(1).wrappedValue = false
        XCTAssertEqual(box.value, [2, 3])
    }

    func testIndex() {
        let elements = ["a", "b", "c"]

        let optionalBox = Box<String?>(nil)
        let optionalIndex = optionalBox.binding.index(elements)
        XCTAssertNil(optionalIndex.wrappedValue)
        optionalBox.value = "b"
        XCTAssertEqual(optionalIndex.wrappedValue, 1)
        optionalBox.value = "z"
        XCTAssertNil(optionalIndex.wrappedValue)
        optionalIndex.wrappedValue = 2
        XCTAssertEqual(optionalBox.value, "c")
        optionalIndex.wrappedValue = 10
        XCTAssertNil(optionalBox.value)

        let box = Box("a")
        let index = box.binding.index(elements)
        XCTAssertEqual(index.wrappedValue, 0)
        index.wrappedValue = 2
        XCTAssertEqual(box.value, "c")
        // Out of bounds indices are ignored
        index.wrappedValue = 10
        XCTAssertEqual(box.value, "c")
    }

    func testIsEqual() {
        enum Selection: Hashable {
            case none, first, second
        }
        let box = Box(Selection.none)
        let isFirst = box.binding.isEqual(to: .first, defaultValue: .none)
        XCTAssertFalse(isFirst.wrappedValue)
        isFirst.wrappedValue = true
        XCTAssertEqual(box.value, .first)
        XCTAssert(isFirst.wrappedValue)
        isFirst.wrappedValue = false
        XCTAssertEqual(box.value, Selection.none)

        let optionalBox = Box<Selection?>(nil)
        let isSecond = optionalBox.binding.isEqual(to: .second)
        XCTAssertFalse(isSecond.wrappedValue)
        isSecond.wrappedValue = true
        XCTAssertEqual(optionalBox.value, .second)
        isSecond.wrappedValue = false
        XCTAssertNil(optionalBox.value)
    }

    func testIsEqualNonHashable() {
        struct Value: Equatable {
            var id: Int
        }
        let box = Box(Value(id: 0))
        let isOne = box.binding.isEqual(to: Value(id: 1), defaultValue: Value(id: 0))
        XCTAssertFalse(isOne.wrappedValue)
        isOne.wrappedValue = true
        XCTAssertEqual(box.value, Value(id: 1))
        isOne.wrappedValue = false
        XCTAssertEqual(box.value, Value(id: 0))

        let optionalBox = Box<Value?>(nil)
        let isTwo = optionalBox.binding.isEqual(to: Value(id: 2))
        isTwo.wrappedValue = true
        XCTAssertEqual(optionalBox.value, Value(id: 2))
        isTwo.wrappedValue = false
        XCTAssertNil(optionalBox.value)
    }

    func testOptionalDynamicMember() {
        struct Model: Hashable {
            var name: String
            var nickname: String?
        }
        let box = Box<Model?>(nil)
        XCTAssertNil(box.binding.name.wrappedValue)
        XCTAssertNil(box.binding.nickname.wrappedValue)

        box.value = Model(name: "Name", nickname: nil)
        XCTAssertEqual(box.binding.name.wrappedValue, "Name")
        XCTAssertNil(box.binding.nickname.wrappedValue)

        box.binding.name.wrappedValue = "New"
        XCTAssertEqual(box.value?.name, "New")
        box.binding.nickname.wrappedValue = "Nick"
        XCTAssertEqual(box.value?.nickname, "Nick")
    }

    func testProjecting() {
        struct DoubleTransform: BindingTransform {
            struct InvalidValue: Error { }

            func get(_ value: Int) -> Int {
                value * 2
            }

            func set(_ newValue: Int) throws -> Int {
                guard newValue.isMultiple(of: 2) else { throw InvalidValue() }
                return newValue / 2
            }
        }
        let box = Box(2)
        let projected = box.binding.projecting(DoubleTransform())
        XCTAssertEqual(projected.wrappedValue, 4)
        projected.wrappedValue = 10
        XCTAssertEqual(box.value, 5)
        // Failed transforms leave the value unchanged
        projected.wrappedValue = 3
        XCTAssertEqual(box.value, 5)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testFormat() {
        let format = IntegerFormatStyle<Int>().grouping(.never)
        let box = Box(42)
        let formatted = box.binding.format(format)
        XCTAssertEqual(formatted.wrappedValue, "42")
        formatted.wrappedValue = "1000"
        XCTAssertEqual(box.value, 1000)
        formatted.wrappedValue = "abc"
        XCTAssertEqual(box.value, 1000)

        let optionalBox = Box<Int?>(nil)
        let optionalFormatted = optionalBox.binding.format(format, defaultValue: "-")
        XCTAssertEqual(optionalFormatted.wrappedValue, "-")
        optionalFormatted.wrappedValue = "7"
        XCTAssertEqual(optionalBox.value, 7)
        XCTAssertEqual(optionalFormatted.wrappedValue, "7")
    }

    func testStateOrBinding() {
        let box = Box(1)
        let wrapper = StateOrBinding<Int>(box.binding)
        XCTAssertEqual(wrapper.wrappedValue, 1)
        wrapper.wrappedValue = 2
        XCTAssertEqual(box.value, 2)
        wrapper.projectedValue.wrappedValue = 3
        XCTAssertEqual(box.value, 3)

        XCTAssertEqual(StateOrBinding(nil, defaultValue: 5).wrappedValue, 5)
        XCTAssertEqual(StateOrBinding(box.binding, defaultValue: 5).wrappedValue, 3)
        XCTAssertNil(StateOrBinding<Int?>(Optional<Binding<Int?>>.none).wrappedValue)
        XCTAssertEqual(StateOrBinding(10).wrappedValue, 10)
    }
}
