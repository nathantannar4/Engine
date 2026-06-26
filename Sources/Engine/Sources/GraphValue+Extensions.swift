//
// Copyright (c) Nathan Tannar
//

import Darwin
import SwiftUI

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private typealias GraphValueUnsafeBitCastFunction<A, B> =
    @convention(thin) (
        _GraphValue<A>,
        B.Type,
        UnsafeRawPointer,
        UnsafeRawPointer
    ) -> _GraphValue<B>

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
nonisolated(unsafe) private let graphValueUnsafeBitCastSymbol = dlsym(
    UnsafeMutableRawPointer(bitPattern: -2), // RTLD_DEFAULT
    "$s7SwiftUI11_GraphValueV13unsafeBitCast2toACyqd__Gqd__m_tlF"
)

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private typealias GraphValueUnsafeCastFunction<A, B> =
    @convention(thin) (
        _GraphValue<A>,
        B.Type,
        UnsafeRawPointer,
        UnsafeRawPointer
    ) -> _GraphValue<B>

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
nonisolated(unsafe) private let graphValueUnsafeCastSymbol = dlsym(
    UnsafeMutableRawPointer(bitPattern: -2), // RTLD_DEFAULT
    "$s7SwiftUI11_GraphValueV10unsafeCast2toACyqd__Gqd__m_tlF"
)

extension _GraphValue {

    func unsafeCast<T>(to _: T.Type) -> _GraphValue<T> {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            let valueMetadata = unsafeBitCast(Value.self, to: UnsafeRawPointer.self)
            let targetMetadata = unsafeBitCast(T.self, to: UnsafeRawPointer.self)

            if MemoryLayout<Value>.size == MemoryLayout<T>.size,
                let symbol = graphValueUnsafeBitCastSymbol
            {
                let function = unsafeBitCast(
                    symbol,
                    to: GraphValueUnsafeBitCastFunction<Value, T>.self
                )
                return function(self, T.self, valueMetadata, targetMetadata)
            } else if let symbol = graphValueUnsafeCastSymbol {
                let function = unsafeBitCast(
                    symbol,
                    to: GraphValueUnsafeCastFunction<Value, T>.self
                )
                return function(self, T.self, valueMetadata, targetMetadata)
            }
        }

        return unsafeBitCast(self, to: _GraphValue<T>.self)
    }
}
