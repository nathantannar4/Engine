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
    precondition(symbol != nil, "'$s7SwiftUI11_GraphValueV13unsafeBitCast2toACyqd__Gqd__m_tlF' Symbol Not Found")
    let function = unsafeBitCast(symbol!, to: Function.self)
    let newValue = function(
        graphValue,
        B.self,
        unsafeBitCast(A.self, to: UnsafeRawPointer.self),
        unsafeBitCast(B.self, to: UnsafeRawPointer.self)
    )
    return newValue
}

@available(iOS, introduced: 18.0, obsoleted: 27.1, message: "Symbol Not Found")
@available(macOS, introduced: 15.0, obsoleted: 27.1, message: "Symbol Not Found")
@available(tvOS, introduced: 18.0, obsoleted: 27.1, message: "Symbol Not Found")
@available(watchOS, introduced: 11.0, obsoleted: 27.1, message: "Symbol Not Found")
@available(visionOS, introduced: 2.0, obsoleted: 27.1, message: "Symbol Not Found")
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
    precondition(symbol != nil, "'$s7SwiftUI11_GraphValueV10unsafeCast2toACyqd__Gqd__m_tlF' Symbol Not Found")
    let function = unsafeBitCast(symbol!, to: Function.self)
    let newValue = function(
        graphValue,
        B.self,
        unsafeBitCast(A.self, to: UnsafeRawPointer.self),
        unsafeBitCast(B.self, to: UnsafeRawPointer.self)
    )
    return newValue
}

private func GraphValueUnsafeCastAttribute<A, B>(
    _ graphValue: _GraphValue<A>,
    to _: B.Type
) -> _GraphValue<B> {
    typealias Function = @convention(c) (
        UnsafeRawPointer,
        UInt32
    ) -> UInt32
    let symbol = dlsym(
        UnsafeMutableRawPointer(bitPattern: -2), // RTLD_DEFAULT
        "$s14AttributeGraph0A0V10unsafeCast2toACyqd__Gqd__m_tlF"
    )
    precondition(symbol != nil, "'$s14AttributeGraph0A0V10unsafeCast2toACyqd__Gqd__m_tlF' Symbol Not Found")
    let function = unsafeBitCast(symbol!, to: Function.self)
    let newValue = function(
        unsafeBitCast(B.self, to: UnsafeRawPointer.self),
        unsafeBitCast(graphValue, to: UInt32.self)
    )
    return unsafeBitCast(newValue, to: _GraphValue<B>.self)
}

extension _GraphValue {

    func unsafeCast<T>(to _: T.Type) -> _GraphValue<T> {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            if MemoryLayout<Value>.size == MemoryLayout<T>.size {
                return GraphValueUnsafeBitCast(self, to: T.self)
            } else if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                return GraphValueUnsafeCastAttribute(self, to: T.self)
            } else {
                return GraphValueUnsafeCast(self, to: T.self)
            }
        } else {
            return unsafeBitCast(self, to: _GraphValue<T>.self)
        }
    }
}
