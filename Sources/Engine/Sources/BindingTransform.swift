//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

/// A protocol for defining a transform for a `Binding`
public protocol BindingTransform: Hashable {
    /// The type of the source value.
    associatedtype Input
    /// The type of the projected value.
    associatedtype Output

    /// Transforms the source value to the projected value.
    func get(_ value: Input) -> Output
    /// Transforms a new projected value back to the source value.
    ///
    /// Throw an error to leave the source value unchanged.
    func set(_ newValue: Output) throws -> Input
}

extension Binding {

    /// Projects a `Binding` with the ``BindingTransform``
    ///
    /// If the transform throws when setting a new value, the value is left unchanged.
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
