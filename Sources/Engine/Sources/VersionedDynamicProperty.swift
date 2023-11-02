//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A dynamic property that is statically conditional on version availability
///
/// Stored properties cannot be annotated with availability, which can make using
/// a newer dynamic properties, such as `FocusState`, challenging. 
///
/// > Tip: Use ``VersionedProperty`` to aide with backwards compatibility.
///
/// For example, a `FocusState` wrapped as follows:
///
///     @propertyWrapper
///     struct VersionedFocusState<Value: Hashable>: VersionedDynamicProperty {
///
///         @VersionedValue var storage: any DynamicProperty
///
///         @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
///         var v3Property: FocusState<Value> {
///             storage as! FocusState<Value>
///         }
///
///         init() where Value == Bool {
///             if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
///                 self.storage = FocusState<Bool>()
///             } else {
///                 self._storage = .unavailable
///             }
///         }
///
///         init<T>() where Value == T?, T: Hashable {
///             if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
///                 self.storage = FocusState<Optional<Value>>()
///             } else {
///                 self._storage = .unavailable
///             }
///         }
///
///         mutating func update() {
///             storage.update()
///         }
///
///         var wrappedValue: VersionedValue<Value> {
///             get {
///                 if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
///                     return .available(v3Property.wrappedValue)
///                 } else {
///                     return .unavailable
///                 }
///             }
///             nonmutating set {
///                 if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
///                     v3Property.wrappedValue = newValue.wrappedValue
///                 }
///             }
///         }
///     }
///
///     struct VersionedFocusStateModifier<Value: Hashable>: VersionedViewModifier {
///         var state: VersionedFocusState<Value>
///         var condition: Value
///
///         init(_ state: VersionedFocusState<Bool>) where Value == Bool {
///             self.state = state
///             self.condition = true
///         }
///
///         init(_ state: VersionedFocusState<Value>, equals condition: Value) {
///             self.state = state
///             self.condition = condition
///         }
///
///         @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
///         func v3Body(content: Content) -> some View {
///             content
///                 .focused(state.v3Property.projectedValue, equals: condition)
///         }
///     }
///
public protocol VersionedDynamicProperty: DynamicProperty {
    associatedtype V5Property: DynamicProperty = V4Property

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, xrOS 1.0, *)
    var v5Property: V5Property { get }

    associatedtype V4Property: DynamicProperty = V3Property

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    var v4Property: V4Property { get }

    associatedtype V3Property: DynamicProperty = V2Property

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var v3Property: V3Property { get }

    associatedtype V2Property: DynamicProperty = V1Property

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var v2Property: V2Property { get }

    associatedtype V1Property: DynamicProperty = EmptyDynamicProperty

    var v1Property: V1Property { get }
}

extension VersionedDynamicProperty where V5Property == V4Property {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, xrOS 1.0, *)
    public var v5Property: V5Property { v4Property }
}

extension VersionedDynamicProperty where V4Property == V3Property {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Property: V4Property { v3Property }
}

extension VersionedDynamicProperty where V3Property == V2Property {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var v3Property: V3Property { v2Property }
}

extension VersionedDynamicProperty where V2Property == V1Property {
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public var v2Property: V2Property { v1Property }
}

extension VersionedDynamicProperty where V1Property == EmptyDynamicProperty {
    public var v1Property: V1Property { EmptyDynamicProperty() }
}

/// An empty `DynamicProperty`
@frozen
public struct EmptyDynamicProperty: DynamicProperty {

    @inlinable
    public init() { }

    public static func _makeProperty<V>(
        in buffer: inout _DynamicPropertyBuffer,
        container: _GraphValue<V>,
        fieldOffset: Int,
        inputs: inout _GraphInputs
    ) { }
}

/// A type for wrapping values based on version availability
@propertyWrapper
@frozen
public enum VersionedValue<T> {

    case unavailable
    case available(T)

    public init(wrappedValue: T) {
        self = .available(wrappedValue)
    }

    public init() {
        self = .unavailable
    }

    public var wrappedValue: T {
        get {
            switch self {
            case .available(let value):
                return value
            case .unavailable:
                fatalError("wrappedValue should not be called, \(String(describing: T.self)) is unavailable")
            }
        }
        set {
            self = .available(newValue)
        }
    }
}

extension VersionedDynamicProperty {
    public static func _makeProperty<V>(
        in buffer: inout _DynamicPropertyBuffer,
        container: _GraphValue<V>,
        fieldOffset: Int,
        inputs: inout _GraphInputs
    ) {
        #if !DEBUG
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, xrOS 1.0, *) {
            V5Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            V4Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
        } else if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            V3Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            V2Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
        } else {
            V1Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
        }
        #else
        /// Support ``VersionInput`` for development support
        let version = inputs[VersionInputKey.self]
        switch version {
        case .v5:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, xrOS 1.0, *) {
                V5Property._makeProperty(
                    in: &buffer,
                    container: container,
                    fieldOffset: fieldOffset,
                    inputs: &inputs
                )
                return
            }
        case .v4:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                V4Property._makeProperty(
                    in: &buffer,
                    container: container,
                    fieldOffset: fieldOffset,
                    inputs: &inputs
                )
                return
            }
        case .v3:
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                V3Property._makeProperty(
                    in: &buffer,
                    container: container,
                    fieldOffset: fieldOffset,
                    inputs: &inputs
                )
                return
            }
        case .v2:
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                V2Property._makeProperty(
                    in: &buffer,
                    container: container,
                    fieldOffset: fieldOffset,
                    inputs: &inputs
                )
                return
            }
        case .v1:
            V1Property._makeProperty(
                in: &buffer,
                container: container,
                fieldOffset: fieldOffset,
                inputs: &inputs
            )
            return
        default:
            break
        }
        EmptyDynamicProperty._makeProperty(
            in: &buffer,
            container: container,
            fieldOffset: fieldOffset,
            inputs: &inputs
        )
        #endif
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var _propertyBehaviors: UInt32 {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, xrOS 1.0, *) {
            return V5Property._propertyBehaviors
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return V4Property._propertyBehaviors
        } else {
            return V3Property._propertyBehaviors
        }
    }
}
