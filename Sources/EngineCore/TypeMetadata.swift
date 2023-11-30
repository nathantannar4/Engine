//
// Copyright (c) Nathan Tannar
//

import Foundation

protocol TypeMetadata {
    associatedtype Layout

    var ptr: UnsafeRawPointer { get }
}

extension TypeMetadata {
    var type: Any.Type {
        unsafeBitCast(ptr, to: Any.Type.self)
    }

    var layout: Layout {
        ptr.load(as: Layout.self)
    }
}

struct Metadata<Kind: TypeMetadata>: TypeMetadata {
    typealias Layout = Kind.Layout

    var ptr: UnsafeRawPointer

    init?(_ type: Any.Type) {
        let ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
        guard let kind = MetadataKind(ptr: ptr) else {
            return nil
        }
        switch kind {
        case .tuple:
            guard Kind.self == TupleMetadata.self else {
                return nil
            }
            self.ptr = ptr
        default:
            return nil
        }
    }

    subscript<Value>(_ keyPath: KeyPath<Kind, Value>) -> Value {
        let kind = unsafeBitCast(ptr, to: Kind.self)
        return kind[keyPath: keyPath]
    }
}

struct TupleMetadata: TypeMetadata {
    struct Layout {
        let kind: Int
        let numberOfElements: Int
        let labels: UnsafePointer<CChar>?
    }

    struct Element: TypeMetadata {
        struct Layout {
            #if canImport(Darwin)
            typealias Offset = Int
            #else
            typealias Offset = UInt32
            #endif

            let type: Any.Type
            #if canImport(Darwin)
            let offset: Offset
            #else
            let offset: Offset
            let padding: UInt32
            #endif
        }

        let ptr: UnsafeRawPointer

        var type: Any.Type {
            layout.type
        }

        var offset: Layout.Offset {
            layout.offset
        }
    }

    let ptr: UnsafeRawPointer

    var numberOfElements: Int {
        layout.numberOfElements
    }

    var elements: [Element] {
        Array(unsafeUninitializedCapacity: numberOfElements) {
            for i in 0..<numberOfElements {
                let address = trailing.offset(of: i, as: Element.Layout.self)
                $0[i] = Element(ptr: address)
            }
            $1 = numberOfElements
        }
    }
}

enum MetadataKind: Int {
    case `class` = 0

    // (0 | Flags.isNonHeap)
    case `struct` = 512

    // (1 | Flags.isNonHeap)
    case `enum` = 513

    // (2 | Flags.isNonHeap)
    case optional = 514

    // (3 | Flags.isNonHeap)
    case foreignClass = 515

    // (0 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case opaque = 768

    // (1 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case tuple = 769

    // (2 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case function = 770

    // (3 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case existential = 771

    // (4 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case metatype = 772

    // (5 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case objcClassWrapper = 773

    // (6 | Flags.isRuntimePrivate | Flags.isNonHeap)
    case existentialMetatype = 774

    // (0 | Flags.isNonType)
    case heapLocalVariable = 1024

    // (0 | Flags.isRuntimePrivate | Flags.isNonType)
    case heapGenericLocalVariable = 1280

    // (1 | Flags.isRuntimePrivate | Flags.isNonType)
    case errorObject = 1281

    init?(ptr: UnsafeRawPointer) {
        let rawValue = ptr.load(as: Int.self)
        self.init(rawValue: rawValue)
    }
}

extension TypeMetadata {
    var trailing: UnsafeRawPointer {
        ptr + MemoryLayout<Layout>.size
    }

    func address<T>(
        for field: KeyPath<Layout, T>
    ) -> UnsafeRawPointer {
        let offset = MemoryLayout<Layout>.offset(of: field)!
        return ptr + offset
    }
}
