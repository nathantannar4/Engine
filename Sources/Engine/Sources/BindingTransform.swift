//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

/// A protocol for defining a transform for a `Binding`
public protocol BindingTransform {
    associatedtype Input
    associatedtype Output

    func get(_ value: Input) -> Output
    func set(_ newValue: Output, oldValue: @autoclosure () -> Input) throws -> Input
}

extension Binding {

    /// Projects a `Binding` with the `transform`
    @inlinable
    public func projecting<Transform: BindingTransform>(
        _ transform: Transform
    ) -> Binding<Transform.Output> where Transform.Input == Value {
        Binding<Transform.Output> {
            transform.get(wrappedValue)
        } set: { newValue, transaction in
            do {
                self.transaction(transaction).wrappedValue = try transform.set(newValue, oldValue: wrappedValue)
            } catch {
                os_log(.error, log: .default, "Projection %{public}@ failed with error: %{public}@", String(describing: Self.self), error.localizedDescription)
            }
        }
    }
}
