//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

final class RuntimeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testConformsToProtocol() {
        struct MyView: View {
            var body: some View {
                EmptyView()
            }
        }
        XCTAssertNotNil(ViewProtocolDescriptor.conformance(of: MyView.self))
    }

    func testIsClassType() {
        struct MyStruct { }
        XCTAssertFalse(swift_getIsClassType(MyStruct.self))
        XCTAssertFalse(swift_getIsClassType(MyStruct()))

        class MyClass { }
        XCTAssert(swift_getIsClassType(MyClass.self))
        XCTAssert(swift_getIsClassType(MyClass()))
    }

    func testRuntimeStruct() throws {
        struct MyStruct {
            var intValue: Int
            private var structValue: MyInternalStruct

            private struct MyInternalStruct {
                var boolValue: Bool
            }

            init() {
                self.intValue = 1
                self.structValue = MyInternalStruct(boolValue: true)
            }
        }

        var value = MyStruct()
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Any.self, value) as? Int,
            1
        )
        try swift_setFieldValue("intValue", 2, &value)
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Int.self, value),
            2
        )
        XCTAssertThrowsError(
            try swift_setFieldValue("intValue", false, &value)
        )
        XCTAssertThrowsError(
            try swift_getFieldValue("intValue", Bool.self, value)
        )
        var privateValue = try swift_getFieldValue("structValue", Any.self, value)
        try XCTAssertEqual(
            swift_getFieldValue("boolValue", Any.self, privateValue) as? Bool,
            true
        )
        try swift_setFieldValue("boolValue", false, &privateValue)
        try XCTAssertEqual(
            swift_getFieldValue("boolValue", Bool.self, privateValue),
            false
        )
        try swift_setFieldValue("structValue", privateValue, &value)

        var optionalValue: MyStruct? = value
        try swift_setFieldValue("intValue", 3, &optionalValue)
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Any.self, optionalValue) as? Int,
            3
        )

        struct MyGenericStruct<Wrapped> { }
        let generics = try XCTUnwrap(swift_getStructGenerics(for: MyGenericStruct<Int>.self))
        XCTAssertEqual(generics.count, 1)
        XCTAssertEqual(
            unsafeBitCast(generics[0], to: UnsafeRawPointer.self),
            unsafeBitCast(Int.self, to: UnsafeRawPointer.self)
        )
    }

    func testRuntimeClass() throws {
        class MyClass {
            var intValue: Int
            var objectValue: MyInternalClass

            private class MyInternalClass { }

            init() {
                self.intValue = 1
                self.objectValue = MyInternalClass()
            }

        }

        let value = MyClass()
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Any.self, value) as? Int,
            1
        )
        try swift_setFieldValue("intValue", 2, value)
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Int.self, value),
            2
        )
        XCTAssertThrowsError(
            try swift_setFieldValue("intValue", false, value)
        )
        XCTAssertThrowsError(
            try swift_getFieldValue("intValue", Bool.self, value)
        )
        let privateValue = try swift_getFieldValue("objectValue", Any.self, value)
        try swift_setFieldValue("objectValue", privateValue, value)
        
        let optionalValue: MyClass? = value
        try swift_setFieldValue("intValue", 3, optionalValue)
        try XCTAssertEqual(
            swift_getFieldValue("intValue", Any.self, optionalValue) as? Int,
            3
        )

        class MyGenericClass<Wrapped> { }
        let generics = try XCTUnwrap(swift_getClassGenerics(for: MyGenericClass<Int>.self))
        XCTAssertEqual(generics.count, 1)
        XCTAssertEqual(
            unsafeBitCast(generics[0], to: UnsafeRawPointer.self),
            unsafeBitCast(Int.self, to: UnsafeRawPointer.self)
        )
    }

    func testRuntimeTuple() throws {
        struct Visitor: TupleVisitor {
            var int: Int
            var string: String
            var double: Double

            mutating func visit<Element>(element: Element, offset: Offset, stop: inout Bool) {
                if Element.self == Int.self {
                    XCTAssertEqual(int, element as? Int)
                    XCTAssertFalse(stop)
                } else if Element.self == String.self {
                    XCTAssertEqual(string, element as? String)
                    XCTAssertFalse(stop)
                } else if Element.self == Double.self {
                    XCTAssertEqual(double, element as? Double)
                    XCTAssert(stop)
                } else {
                    XCTFail()
                }
            }
        }

        let tuple = try XCTUnwrap(Tuple((1, "Hello, World", 2.0)))
        var visitor = Visitor(
            int: 1,
            string: "Hello, World",
            double: 2.0
        )
        tuple.visit(visitor: &visitor)
    }

    #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
    func testHostingView() throws {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let host = _UIHostingView(rootView: EmptyView())
        #else
        let host = NSHostingView(rootView: EmptyView())
        #endif
        print(swift_getFields(host).map(\.field.key))
        if #available(iOS 16.0, tvOS 16.0, *) { } else {
            _ = try swift_getFieldValue("propertiesNeedingUpdate", UInt16.self, host)
        }
        _ = try swift_getFieldValue("_rootView", EmptyView.self, host)
        #if os(iOS) || os(tvOS) || os(visionOS)
        _ = try swift_getFieldValue("allowUIKitAnimations", Int32.self, host)
        if #available(iOS 18.1, tvOS 18.1, *) { } else {
            _ = try swift_getFieldValue("allowUIKitAnimationsForNextUpdate", Bool.self, host)
        }
        #endif
    }
    #endif
}
