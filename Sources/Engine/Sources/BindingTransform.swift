//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

/// A protocol for defining a transform for a `Binding`
public protocol BindingTransform: Hashable {
    associatedtype Input
    associatedtype Output

    func get(_ value: Input) -> Output
    func set(_ newValue: Output) throws -> Input
}

extension Binding {

    /// Projects a `Binding` with the ``BindingTransform``
    @MainActor
    public func projecting<Transform: BindingTransform>(
        _ transform: Transform
    ) -> Binding<Transform.Output> where Transform.Input == Value, Value: Hashable {
        self[keyPath: \.[projecting: transform]]
    }
}

extension Hashable {

    @usableFromInline
    subscript<T: BindingTransform>(projecting transform: T) -> T.Output where Self == T.Input {
        get {
            transform.get(self)
        }
        set {
            do {
                self = try transform.set(newValue)
            } catch {
                os_log(.debug, log: .default, "Projection %{public}@ failed with error: %{public}@", String(describing: Self.self), error.localizedDescription)
            }
        }
    }
}
