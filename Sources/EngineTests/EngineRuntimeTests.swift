//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import Engine

@MainActor
final class RuntimeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

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

    func testPropertyListElement() {
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
        class ElementV6 {
            var fields: PropertyList.ElementFieldsV6

            init(fields: PropertyList.ElementFieldsV6) {
                self.fields = fields
            }
        }

        @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
        class TypedElementV6<Value>: ElementV6 {
            var value: Value
            
            init(value: Value, fields: PropertyList.ElementFieldsV6) {
                self.value = value
                super.init(fields: fields)
            }
        }

        class ElementV1 {
            var fields: PropertyList.ElementFieldsV1

            init(fields: PropertyList.ElementFieldsV1) {
                self.fields = fields
            }
        }

        class TypedElementV1<Value>: ElementV1 {
            var value: Value

            init(value: Value, fields: PropertyList.ElementFieldsV1) {
                self.value = value
                super.init(fields: fields)
            }
        }

        struct StoredValue {
            var id: Int
            var name: String
        }
        let value = StoredValue(id: 100, name: "Hello, World")

        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            let instance = TypedElementV6(value: value, fields: .init(keyType: StoredValue.self, length: 0, skipCount: 0, keyFilter: 0, id: 0))
            let ptr = Unmanaged.passUnretained(instance)
                .toOpaque()
                .assumingMemoryBound(to: PropertyList.ElementLayout<PropertyList.ElementFieldsV6>.self)
            ptr.withUnsafeValuePointer(StoredValue.self, fields: PropertyList.ElementFieldsV6.self) { ptr in
                let storedValue = ptr.pointee.value
                XCTAssertEqual(storedValue.id, value.id)
                XCTAssertEqual(storedValue.name, value.name)
            }
        }
        let instance = TypedElementV1(value: value, fields: .init(keyType: StoredValue.self, length: 0, keyFilter: 0, id: 0))
        let ptr = Unmanaged.passUnretained(instance)
            .toOpaque()
            .assumingMemoryBound(to: PropertyList.ElementLayout<PropertyList.ElementFieldsV1>.self)
        ptr.withUnsafeValuePointer(StoredValue.self, fields: PropertyList.ElementFieldsV1.self) { ptr in
            let storedValue = ptr.pointee.value
            XCTAssertEqual(storedValue.id, value.id)
            XCTAssertEqual(storedValue.name, value.name)
        }
    }
}
