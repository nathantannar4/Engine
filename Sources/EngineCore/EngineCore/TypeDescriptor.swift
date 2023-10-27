//
// Copyright (c) Nathan Tannar
//

/// A protocol to statically define a descriptor to a type's metadata
///
/// See also:
///  - `https://github.com/apple/swift/blob/main/docs/ABI/TypeMetadata.rst`
public protocol TypeDescriptor {
    static var descriptor: UnsafeRawPointer { get }
}

extension TypeDescriptor {
    public static var descriptor: UnsafeRawPointer {
        TypeIdentifier(Self.self).metadata
    }
}
