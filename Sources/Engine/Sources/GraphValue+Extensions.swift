//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@_silgen_name("$s7SwiftUI11_GraphValueV13unsafeBitCast2toACyqd__Gqd__m_tlF")
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
func _GraphValueUnsafeBitCast<A, B>(_ self: _GraphValue<A>, to: B.Type) -> _GraphValue<B>

@_silgen_name("$s7SwiftUI11_GraphValueV10unsafeCast2toACyqd__Gqd__m_tlF")
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
func _GraphValueUnsafeCast<A, B>(_ self: _GraphValue<A>, to: B.Type) -> _GraphValue<B>

extension _GraphValue {

    func unsafeCast<T>(to _: T.Type) -> _GraphValue<T> {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            if MemoryLayout<Value>.size == MemoryLayout<T>.size {
                return _GraphValueUnsafeBitCast(self, to: T.self)
            } else {
                return _GraphValueUnsafeCast(self, to: T.self)
            }
        } else {
            return unsafeBitCast(self, to: _GraphValue<T>.self)
        }
    }
}
