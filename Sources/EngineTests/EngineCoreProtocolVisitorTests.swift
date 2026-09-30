//
// Copyright (c) Nathan Tannar
//

import XCTest
import SwiftUI
@testable import EngineCore

// Not private, so that the type can be looked up by its mangled name
struct CoreProtocolVisitorTestEnvironmentKey: EnvironmentKey {
    static let defaultValue = 42
}

private struct TestViewTraitKey: _ViewTraitKey {
    static var defaultValue: String { "trait" }
}

private struct TestViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

@MainActor
final class CoreProtocolVisitorTests: XCTestCase {

    func testEnvironmentKeyConformance() throws {
        struct Visitor: EnvironmentKeyVisitor {
            var visited: Any.Type?
            var defaultValue: Any?

            mutating func visit<Key: EnvironmentKey>(type: Key.Type) {
                visited = type
                defaultValue = Key.defaultValue
            }
        }

        XCTAssertNil(EnvironmentKeyProtocolDescriptor.conformance(of: Int.self))
        XCTAssertNil(EnvironmentKeyProtocolDescriptor.conformance(of: TestViewTraitKey.self))

        let conformance = try XCTUnwrap(EnvironmentKeyProtocolDescriptor.conformance(of: CoreProtocolVisitorTestEnvironmentKey.self))
        XCTAssertEqual(conformance.metadata, unsafeBitCast(CoreProtocolVisitorTestEnvironmentKey.self, to: UnsafeRawPointer.self))

        var visitor = Visitor()
        conformance.visit(visitor: &visitor)
        XCTAssert(visitor.visited == CoreProtocolVisitorTestEnvironmentKey.self)
        XCTAssertEqual(visitor.defaultValue as? Int, 42)
    }

    func testViewTraitKeyConformance() throws {
        struct Visitor: ViewTraitKeyVisitor {
            var visited: Any.Type?
            var defaultValue: Any?

            mutating func visit<Key: _ViewTraitKey>(type: Key.Type) {
                visited = type
                defaultValue = Key.defaultValue
            }
        }

        XCTAssertNil(ViewTraitKeyProtocolDescriptor.conformance(of: Int.self))
        XCTAssertNil(ViewTraitKeyProtocolDescriptor.conformance(of: CoreProtocolVisitorTestEnvironmentKey.self))

        let conformance = try XCTUnwrap(ViewTraitKeyProtocolDescriptor.conformance(of: TestViewTraitKey.self))
        var visitor = Visitor()
        conformance.visit(visitor: &visitor)
        XCTAssert(visitor.visited == TestViewTraitKey.self)
        XCTAssertEqual(visitor.defaultValue as? String, "trait")
    }

    func testViewModifierConformance() throws {
        struct Visitor: ViewModifierVisitor {
            var visited: Any.Type?

            mutating func visit<Modifier: ViewModifier>(type: Modifier.Type) {
                visited = type
            }
        }

        XCTAssertNil(ViewModifierProtocolDescriptor.conformance(of: Int.self))
        XCTAssertNil(ViewModifierProtocolDescriptor.conformance(of: EmptyView.self))

        let conformance = try XCTUnwrap(ViewModifierProtocolDescriptor.conformance(of: TestViewModifier.self))
        var visitor = Visitor()
        conformance.visit(visitor: &visitor)
        XCTAssert(visitor.visited == TestViewModifier.self)

        // Generic modifiers resolve to their specialized type
        typealias Modified = ModifiedContent<TestViewModifier, EmptyModifier>
        let modifiedConformance = try XCTUnwrap(ViewModifierProtocolDescriptor.conformance(of: Modified.self))
        modifiedConformance.visit(visitor: &visitor)
        XCTAssert(visitor.visited == Modified.self)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testConformanceOfTypeName() throws {
        let name = try XCTUnwrap(_mangledTypeName(CoreProtocolVisitorTestEnvironmentKey.self))
        XCTAssertNotNil(EnvironmentKeyProtocolDescriptor.conformance(of: name))
        XCTAssertNil(ViewModifierProtocolDescriptor.conformance(of: name))
        XCTAssertNil(EnvironmentKeyProtocolDescriptor.conformance(of: "NotAType"))
    }

    func testTypeDescriptorDefault() {
        struct Descriptor: TypeDescriptor { }
        XCTAssertEqual(Descriptor.descriptor, TypeIdentifier(Descriptor.self).metadata)
    }
}
