//
// Copyright (c) Nathan Tannar
//

/// A unique identifier derived from a type
@frozen
public struct TypeIdentifier: Hashable, @unchecked Sendable, CustomDebugStringConvertible {
    /// A pointer to the type's metadata.
    public var metadata: UnsafeRawPointer

    /// Creates an identifier for the type `T`.
    public init<T>(_: T.Type = T.self) {
        self.metadata = unsafeBitCast(T.self, to: UnsafeRawPointer.self)
    }

    public var debugDescription: String {
        _typeName(unsafeBitCast(metadata, to: Any.Type.self), qualified: false)
    }
}
