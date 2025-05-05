//
// Copyright (c) Nathan Tannar
//

import Foundation

extension MainActor {
    static func unsafe<T>(_ body: @MainActor () throws -> T) rethrows -> T {
        #if swift(>=5.9)
        return try MainActor.assumeIsolated {
            try body()
        }
        #else
        return try body()
        #endif
    }
}
