//
// Copyright (c) Nathan Tannar
//

/// A protocol to statically define a descriptor to a type's metadata
///
/// See also:
///  - `https://github.com/apple/swift/blob/main/docs/ABI/TypeMetadata.rst`
public protocol TypeDescriptor {
    /// A pointer to the descriptor, such as a protocol descriptor.
    static var descriptor: UnsafeRawPointer { get }
}

extension TypeDescriptor {
    /// A pointer to the type metadata of the conforming type.
    public static var descriptor: UnsafeRawPointer {
        TypeIdentifier(Self.self).metadata
    }
}
