//
// Copyright (c) Nathan Tannar
//

import Darwin
import SwiftUI

private typealias GraphValueUnsafeBitCastFunction<A, B> =
    @convention(thin) (_GraphValue<A>, B.Type) -> _GraphValue<B>

private typealias GraphValueUnsafeCastFunction<A, B> =
    @convention(thin) (_GraphValue<A>, B.Type) -> _GraphValue<B>

private let graphValueUnsafeBitCastSymbol = dlsym(
    UnsafeMutableRawPointer(bitPattern: -2),
    "$s7SwiftUI11_GraphValueV13unsafeBitCast2toACyqd__Gqd__m_tlF"
)

private let graphValueUnsafeCastSymbol = dlsym(
    UnsafeMutableRawPointer(bitPattern: -2),
    "$s7SwiftUI11_GraphValueV10unsafeCast2toACyqd__Gqd__m_tlF"
)

extension _GraphValue {

    func unsafeCast<T>(to _: T.Type) -> _GraphValue<T> {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            if MemoryLayout<Value>.size == MemoryLayout<T>.size,
                let symbol = graphValueUnsafeBitCastSymbol
            {
                let function = unsafeBitCast(
                    symbol,
                    to: GraphValueUnsafeBitCastFunction<Value, T>.self
                )
                return function(self, T.self)
            } else if let symbol = graphValueUnsafeCastSymbol {
                let function = unsafeBitCast(
                    symbol,
                    to: GraphValueUnsafeCastFunction<Value, T>.self
                )
                return function(self, T.self)
            }
        }

        return unsafeBitCast(self, to: _GraphValue<T>.self)
    }
}
