//
// Copyright (c) Nathan Tannar
//

/// A unique identifier derived from a type
@frozen
public struct TypeIdentifier: Hashable {
    public var metadata: UnsafeRawPointer

    public init<T>(_: T.Type = T.self) {
        self.metadata = unsafeBitCast(T.self, to: UnsafeRawPointer.self)
    }
}
