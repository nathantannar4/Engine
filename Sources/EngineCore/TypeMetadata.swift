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
        let kind = MetadataKind(ptr: ptr) ?? .class
        switch kind {
        case .tuple:
            guard Kind.self == TupleMetadata.self else {
                return nil
            }
            self.ptr = ptr
        case .struct:
            guard Kind.self == StructMetadata.self else {
                return nil
            }
            self.ptr = ptr
        case .class:
            guard Kind.self == ClassMetadata.self else {
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

protocol ContextDescriptor {
    associatedtype Layout
    var ptr: UnsafeRawPointer { get }
}

struct ContextDescriptorLayout {
    let flags: ContextDescriptorFlags
    let parent: UInt32
}

extension ContextDescriptor {
    var layout: Layout {
        ptr.load(as: Layout.self)
    }
}

struct TypeDescriptorLayout {
    let base: ContextDescriptorLayout
    let name: UInt32
    let accessor: UInt32
    let fields: UInt32
}

struct ClassMetadata: TypeMetadata {
    struct Layout {
        let kind: Int
        let superclass: Any.Type?
        let reserved: (Int, Int)
        let rodata: UnsafeRawPointer
        let flags: UInt32
        let instanceAddressPoint: UInt32
        let instanceSize: UInt32
        let instanceAlignMask: UInt16
        let runtimeReserved: UInt16
        let classSize: UInt32
        let classAddressPoint: UInt32
        let descriptor: UnsafePointer<Descriptor>
        let ivarDestroyer: UnsafeRawPointer
    }

    struct Descriptor: ContextDescriptor {
        struct Layout {
            let base: TypeDescriptorLayout
            let superclass: UInt32
            let negativeSizeOrResilientBounds: UInt32
            let positiveSizeOrExtraFlags: UInt32
            let numImmediateMembers: UInt32
            let numFields: UInt32
            let fieldOffsetVectorOffset: UInt32
        }

        let ptr: UnsafeRawPointer

        var negativeSize: Int {
            Int(layout.negativeSizeOrResilientBounds)
        }

        var positiveSize: Int {
            Int(layout.positiveSizeOrExtraFlags)
        }

        var numMembers: Int {
            Int(layout.numImmediateMembers)
        }

        var genericArgumentOffset: Int {
            let flags = TypeContextDescriptorFlags(bits: UInt64(layout.base.base.flags.kindSpecificFlags))
            if flags.classHasResilientSuperclass {
                fatalError("unimplemented")
            } else if flags.classAreImmediateMembersNegative {
                return -negativeSize
            } else {
                return positiveSize - numMembers
            }
        }
    }

    let ptr: UnsafeRawPointer

    var descriptor: Descriptor {
        Descriptor(ptr: ptr.load(as: Layout.self).descriptor)
    }

    var genericArgumentPtr: UnsafeRawPointer {
        ptr.offset(of: descriptor.genericArgumentOffset)
    }

    var genericTypes: [Any.Type]? {
        guard descriptor.layout.base.base.flags.isGeneric else {
            return nil
        }

        let genericContext = TypeGenericContext(
            ptr: descriptor.ptr + MemoryLayout<Descriptor.Layout>.size
        ).layout.base
        let numParams = Int(genericContext.numParams)
        return Array(unsafeUninitializedCapacity: numParams) {
            let gap = genericArgumentPtr
            for i in 0 ..< numParams {
                let type = gap.load(
                    fromByteOffset: i * MemoryLayout<Any.Type>.stride,
                    as: Any.Type.self
                )

                $0[i] = type
            }
            $1 = numParams
        }
    }
}

struct StructMetadata: TypeMetadata {
    struct Layout {
        let kind: Int
        let descriptor: UnsafePointer<Descriptor>
    }

    struct Descriptor: ContextDescriptor {
        struct Layout {
            let base: TypeDescriptorLayout
            let numFields: UInt32
            let fieldOffsetVectorOffset: UInt32
        }

        let ptr: UnsafeRawPointer
    }

    let ptr: UnsafeRawPointer

    var descriptor: Descriptor {
        Descriptor(ptr: ptr.load(as: Layout.self).descriptor)
    }

    var genericArgumentPtr: UnsafeRawPointer {
        ptr + MemoryLayout<Layout>.size
    }

    var genericTypes: [Any.Type]? {
        guard descriptor.layout.base.base.flags.isGeneric else {
            return nil
        }

        let genericContext = TypeGenericContext(
            ptr: descriptor.ptr + MemoryLayout<Descriptor.Layout>.size
        ).layout.base
        let numParams = Int(genericContext.numParams)
        return Array(unsafeUninitializedCapacity: numParams) {
            let gap = genericArgumentPtr
            for i in 0 ..< numParams {
                let type = gap.load(
                    fromByteOffset: i * MemoryLayout<Any.Type>.stride,
                    as: Any.Type.self
                )

                $0[i] = type
            }
            $1 = numParams
        }
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

struct ContextDescriptorFlags {
    let bits: UInt32

    var isGeneric: Bool {
        bits & 0x80 != 0
    }

    var kindSpecificFlags: UInt16 {
        UInt16((bits >> 0x10) & 0xFFFF)
    }
}

struct TypeContextDescriptorFlags {
    var bits: UInt64

    var classAreImmediateMembersNegative: Bool {
        bits & 0x1000 != 0
    }

    var classHasResilientSuperclass: Bool {
        bits & 0x2000 != 0
    }
}

struct GenericContextLayout {
    let numParams: UInt16
    let numRequirements: UInt16
    let numKeyArguments: UInt16
    let numExtraArguments: UInt16
}

struct TypeGenericContext {
    var ptr: UnsafeRawPointer

    struct Layout {
        let instantiationCache: UInt32
        let defaultInstantiationPattern: UInt32
        let base: GenericContextLayout
    }

    var layout: Layout {
        ptr.load(as: Layout.self)
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
