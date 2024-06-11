//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct AnyAnimatableData: VectorArithmetic, Sendable {

    @usableFromInline
    var storage: AnyAnimatableDataStorageBase

    @inlinable
    public init<V: VectorArithmetic>(_ vector: V) {
        storage = AnyAnimatableDataStorage(vector)
    }

    public var magnitudeSquared: Double {
        storage.magnitudeSquared
    }

    public mutating func scale(by rhs: Double) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = storage.copy()
        }
        storage.scale(by: rhs)
    }

    public static let zero: AnyAnimatableData = AnyAnimatableData(EmptyAnimatableData.zero)

    public static func == (lhs: AnyAnimatableData, rhs: AnyAnimatableData) -> Bool {
        lhs.storage.isEqual(to: rhs.storage)
    }

    public static func += (lhs: inout AnyAnimatableData, rhs: AnyAnimatableData) {
        if !isKnownUniquelyReferenced(&lhs.storage) {
            lhs.storage = lhs.storage.copy()
        }
        lhs.storage.add(rhs.storage)
    }

    public static func -= (lhs: inout AnyAnimatableData, rhs: AnyAnimatableData) {
        if !isKnownUniquelyReferenced(&lhs.storage) {
            lhs.storage = lhs.storage.copy()
        }
        lhs.storage.subtract(rhs.storage)
    }

    @_transparent
    public static func + (lhs: AnyAnimatableData, rhs: AnyAnimatableData) -> AnyAnimatableData {
        var ret = lhs
        ret += rhs
        return ret
    }

    @_transparent
    public static func - (lhs: AnyAnimatableData, rhs: AnyAnimatableData) -> AnyAnimatableData {
        var ret = lhs
        ret -= rhs
        return ret
    }

    func `as`<V: VectorArithmetic>(_: V.Type) -> V? {
        storage.as(V.self)
    }
}

@usableFromInline
class AnyAnimatableDataStorageBase: @unchecked Sendable {

    var magnitudeSquared: Double {
        fatalError("base")
    }

    func scale(by rhs: Double) {
        fatalError("base")
    }

    func isEqual(to other: AnyAnimatableDataStorageBase) -> Bool {
        fatalError("base")
    }

    func add(_ other: AnyAnimatableDataStorageBase) {
        fatalError("base")
    }

    func subtract(_ other: AnyAnimatableDataStorageBase) {
        fatalError("base")
    }

    func `as`<V: VectorArithmetic>(_: V.Type) -> V? {
        fatalError("base")
    }

    func copy() -> AnyAnimatableDataStorageBase {
        fatalError("base")
    }
}

@usableFromInline
final class AnyAnimatableDataStorage<
    Vector: VectorArithmetic
>: AnyAnimatableDataStorageBase, @unchecked Sendable {

    var vector: Vector

    @usableFromInline
    init(_ vector: Vector) {
        self.vector = vector
    }

    override var magnitudeSquared: Double {
        vector.magnitudeSquared
    }

    override func scale(by rhs: Double) {
        vector.scale(by: rhs)
    }

    override func isEqual(to other: AnyAnimatableDataStorageBase) -> Bool {
        guard let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector else {
            if other is AnyAnimatableDataStorage<EmptyAnimatableData> {
                return vector == Vector.zero
            }
            return false
        }
        return vector == other
    }

    override func add(_ other: AnyAnimatableDataStorageBase)  {
        guard let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector else {
            return
        }
        vector += other
    }

    override func subtract(_ other: AnyAnimatableDataStorageBase) {
        guard let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector else {
            return
        }
        vector -= other
    }

    override func `as`<V: VectorArithmetic>(_: V.Type) -> V? {
        guard Vector.self == Vector.self else { return nil }
        return unsafeBitCast(vector, to: V.self)
    }

    override func copy() -> AnyAnimatableDataStorageBase {
        AnyAnimatableDataStorage(vector)
    }
}
