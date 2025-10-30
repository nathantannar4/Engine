//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LayoutSubview {

    struct ProxyLayout: Hashable {
        var context: UInt32
        struct Attributes: Hashable {
            var layoutComputer: UInt32
            var traitsList: UInt32
        }
        var attributes: Attributes

        var id: Int {
            var hasher = Hasher()
            hasher.combine(context)
            hasher.combine(attributes)
            return hasher.finalize()
        }
    }

    public typealias ID = Int
    public var id: ID {
        let proxy = try! swift_getFieldValue("proxy", LayoutSubview.ProxyLayout.self, self)
        return proxy.id
    }
}
