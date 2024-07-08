//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct ViewTypeIdentifier: Hashable, CustomDebugStringConvertible {

    private indirect enum Storage: Hashable, CustomDebugStringConvertible {
        case root(TypeIdentifier)
        case subview(Storage, TypeIdentifier)
        case offset(Storage, AnyHashable)

        var debugDescription: String {
            switch self {
            case .root(let id):
                return id.debugDescription
            case .subview(let storage, let id):
                return storage.debugDescription + "->" + id.debugDescription
            case .offset(let storage, let offset):
                return storage.debugDescription + "->" + offset.debugDescription
            }
        }
    }
    private var storage: Storage

    init<Content: View>(_: Content.Type) {
        self.storage = .root(TypeIdentifier(Content.self))
    }

    mutating func append<Content: View>(_: Content.Type) {
        storage = .subview(storage, TypeIdentifier(Content.self))
    }

    func appending<Content: View>(_: Content.Type) -> ViewTypeIdentifier {
        var copy = self
        copy.append(Content.self)
        return copy
    }

    mutating func append<Offset: Hashable>(offset: Offset) {
        storage = .offset(storage, AnyHashable(offset))
    }

    func appending<Offset: Hashable>(offset: Offset) -> ViewTypeIdentifier{
        var copy = self
        copy.append(offset: offset)
        return copy
    }

    public var debugDescription: String {
        storage.debugDescription
    }
}
