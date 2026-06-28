//
// Copyright (c) Nathan Tannar
//

import Darwin
import SwiftUI

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private func GraphValueUnsafeBitCast<A, B>(
    _ graphValue: _GraphValue<A>,
    to _: B.Type
) -> _GraphValue<B> {
    typealias Function = @convention(thin) (
        _GraphValue<A>,
        B.Type,
        UnsafeRawPointer,
        UnsafeRawPointer
    ) -> _GraphValue<B>
    let symbol = dlsym(
        UnsafeMutableRawPointer(bitPattern: -2), // RTLD_DEFAULT
        "$s7SwiftUI11_GraphValueV13unsafeBitCast2toACyqd__Gqd__m_tlF"
    )
    let function = unsafeBitCast(symbol!, to: Function.self)
    return function(
        graphValue,
        B.self,
        unsafeBitCast(A.self, to: UnsafeRawPointer.self),
        unsafeBitCast(B.self, to: UnsafeRawPointer.self)
    )
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private func GraphValueUnsafeCast<A, B>(
    _ graphValue: _GraphValue<A>,
    to _: B.Type
) -> _GraphValue<B> {
    typealias Function = @convention(thin) (
        _GraphValue<A>,
        B.Type,
        UnsafeRawPointer,
        UnsafeRawPointer
    ) -> _GraphValue<B>
    let symbol = dlsym(
        UnsafeMutableRawPointer(bitPattern: -2), // RTLD_DEFAULT
        "$s7SwiftUI11_GraphValueV10unsafeCast2toACyqd__Gqd__m_tlF"
    )
    let function = unsafeBitCast(symbol!, to: Function.self)
    return function(
        graphValue,
        B.self,
        unsafeBitCast(A.self, to: UnsafeRawPointer.self),
        unsafeBitCast(B.self, to: UnsafeRawPointer.self)
    )
}

extension _GraphValue {

    func unsafeCast<T>(to _: T.Type) -> _GraphValue<T> {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            if MemoryLayout<Value>.size == MemoryLayout<T>.size {
                return GraphValueUnsafeBitCast(self, to: T.self)
            } else {
                return GraphValueUnsafeCast(self, to: T.self)
            }
        } else {
            return unsafeBitCast(self, to: _GraphValue<T>.self)
        }
    }
}
