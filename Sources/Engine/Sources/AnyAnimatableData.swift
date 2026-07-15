//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A type erased `AnimatableData`
@frozen
public struct AnyAnimatableData: VectorArithmetic, Sendable {

    @usableFromInline
    var storage: AnyAnimatableDataStorageBase

    @inlinable
    public init<V: VectorArithmetic>(_ vector: V) {
        storage = AnyAnimatableDataStorage(vector)
    }

    public var magnitudeSquared: Double {
        return storage.magnitudeSquared
    }

    public mutating func scale(by rhs: Double) {
        storage = storage.scaled(by: rhs)
    }

    public static let zero: AnyAnimatableData = AnyAnimatableData(EmptyAnimatableData.zero)

    public static func == (lhs: AnyAnimatableData, rhs: AnyAnimatableData) -> Bool {
        lhs.storage.isEqual(to: rhs.storage)
    }

    public static func += (lhs: inout AnyAnimatableData, rhs: AnyAnimatableData) {
        lhs.storage = lhs.storage.adding(rhs.storage)
    }

    public static func -= (lhs: inout AnyAnimatableData, rhs: AnyAnimatableData) {
        lhs.storage = lhs.storage.subtracting(rhs.storage)
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

    public func value<V: VectorArithmetic>(as _: V.Type) -> V? {
        storage.value(as: V.self)
    }
}

@usableFromInline
class AnyAnimatableDataStorageBase: @unchecked Sendable, CustomDebugStringConvertible {

    @usableFromInline
    var debugDescription: String {
        fatalError("base")
    }

    var magnitudeSquared: Double {
        fatalError("base")
    }

    func scaled(by rhs: Double) -> AnyAnimatableDataStorageBase {
        fatalError("base")
    }

    func isEqual(to other: AnyAnimatableDataStorageBase) -> Bool {
        fatalError("base")
    }

    func adding(_ other: AnyAnimatableDataStorageBase) -> AnyAnimatableDataStorageBase {
        fatalError("base")
    }

    func subtracting(_ other: AnyAnimatableDataStorageBase) -> AnyAnimatableDataStorageBase {
        fatalError("base")
    }

    func value<V: VectorArithmetic>(as _: V.Type) -> V? {
        fatalError("base")
    }
}

@usableFromInline
final class AnyAnimatableDataStorage<
    Vector: VectorArithmetic
>: AnyAnimatableDataStorageBase, @unchecked Sendable {

    let vector: Vector

    @usableFromInline
    init(_ vector: Vector) {
        self.vector = vector
    }

    override var debugDescription: String {
        "\(vector)"
    }

    override var magnitudeSquared: Double {
        vector.magnitudeSquared
    }

    override func scaled(by rhs: Double) -> AnyAnimatableDataStorageBase {
        AnyAnimatableDataStorage(vector.scaled(by: rhs))
    }

    override func isEqual(to other: AnyAnimatableDataStorageBase) -> Bool {
        if let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector {
            return vector == other
        } else if other is AnyAnimatableDataStorage<EmptyAnimatableData> {
            return vector == Vector.zero
        }
        return false
    }

    override func adding(_ other: AnyAnimatableDataStorageBase) -> AnyAnimatableDataStorageBase {
        if let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector {
            return AnyAnimatableDataStorage(vector + other)
        } else if other is AnyAnimatableDataStorage<EmptyAnimatableData> {
            return self
        } else if self is AnyAnimatableDataStorage<EmptyAnimatableData> {
            return other
        }
        return self
    }

    override func subtracting(_ other: AnyAnimatableDataStorageBase) -> AnyAnimatableDataStorageBase {
        if let other = (other as? AnyAnimatableDataStorage<Vector>)?.vector {
            return AnyAnimatableDataStorage(vector - other)
        } else if other is AnyAnimatableDataStorage<EmptyAnimatableData> {
            return self
        } else if self is AnyAnimatableDataStorage<EmptyAnimatableData> {
            return other.scaled(by: -1)
        }
        return self
    }

    override func value<V: VectorArithmetic>(as _: V.Type) -> V? {
        guard Vector.self == V.self else { return nil }
        return unsafeBitCast(vector, to: V.self)
    }
}

// MARK: - Previews

struct AnyAnimatableData_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct CustomShape: Shape, Animatable {
        var cornerRadius: CGFloat

        nonisolated func path(in rect: CGRect) -> Path {
            RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        }

        var animatableData: AnyAnimatableData {
            get { AnyAnimatableData(cornerRadius) }
            set {
                print(newValue)
                if let newValue = newValue.value(as: CGFloat.self) {
                    cornerRadius = newValue
                }
            }
        }
    }

    struct Preview: View {

        @State var flag = false

        var body: some View {
            let cornerRadius: CGFloat = flag ? 50 : 25
            VStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.red)
                    .frame(height: 100)

                CustomShape(cornerRadius: cornerRadius)
                    .fill(Color.blue)
                    .frame(height: 100)

                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }
            }
            .padding()
        }
    }
}
