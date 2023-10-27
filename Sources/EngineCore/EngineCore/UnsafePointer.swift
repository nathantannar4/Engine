//
// Copyright (c) Nathan Tannar
//

import Foundation

@_transparent
public func unsafePartialBitCast<T, U>(_ x: T, to _: U.Type) -> U {
    withUnsafePointer(to: x) { ptr in
        ptr.withMemoryRebound(to: U.self, capacity: 1) { ptr in
            return ptr.pointee
        }
    }
}

@_transparent
public func withMemoryRebound<T, U, ReturnType>(_ x: inout T, to _: U.Type, _ body: ((inout U) -> ReturnType)) -> ReturnType {
    withUnsafeMutablePointer(to: &x) { ptr in
        ptr.withMemoryRebound(to: U.self, capacity: 1) { ptr in
            body(&ptr.pointee)
        }
    }
}

extension UnsafeRawPointer {
    @_transparent
    func offset(
        of offset: Int
    ) -> UnsafeRawPointer {
        advanced(by: MemoryLayout<Int>.size * offset)
    }

    @_transparent
    func offset<T>(
        of offset: Int,
        as type: T.Type
    ) -> UnsafeRawPointer {
        advanced(by: MemoryLayout<T>.size * offset)
    }
}

extension UnsafeMutablePointer {
    var value: Pointee {
        @_transparent
        unsafeAddress {
            return UnsafePointer(self)
        }
        @_transparent
        nonmutating unsafeMutableAddress {
            return self
        }
    }
}
