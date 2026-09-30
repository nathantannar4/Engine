//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A type that is dynamically either `TrueContent` or `FalseContent`.
///
/// > Note: Similar to `SwiftUI._ConditionalContent` but with the underlying storage
/// made public
@frozen
public struct ConditionalContent<
    TrueContent,
    FalseContent
> {

    /// The underlying content, which is either `TrueContent` or `FalseContent`.
    @frozen
    public enum Storage: @unchecked Sendable {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }

    /// The underlying content.
    public var storage: Storage

    /// Creates an instance with the `TrueContent`.
    @inlinable
    public init(_ trueContent: TrueContent) {
        self.storage = .trueContent(trueContent)
    }

    /// Creates an instance with the `FalseContent`.
    @inlinable
    public init(_ falseContent: FalseContent) {
        self.storage = .falseContent(falseContent)
    }
}

extension ConditionalContent: Animatable where TrueContent: Animatable, FalseContent: Animatable {
    /// The animatable data of the current content.
    ///
    /// Setting a value whose underlying type does not match the current content has no effect.
    public var animatableData: AnyAnimatableData {
        get {
            switch storage {
            case .trueContent(let layout):
                return AnyAnimatableData(layout.animatableData)
            case .falseContent(let layout):
                return AnyAnimatableData(layout.animatableData)
            }
        }
        set {
            switch storage {
            case .trueContent(var layout):
                if let newValue = newValue.value(as: TrueContent.AnimatableData.self) {
                    layout.animatableData = newValue
                    storage = .trueContent(layout)
                }
            case .falseContent(var layout):
                if let newValue = newValue.value(as: FalseContent.AnimatableData.self) {
                    layout.animatableData = newValue
                    storage = .falseContent(layout)
                }
            }
        }
    }
}

extension ConditionalContent: Sendable where TrueContent: Sendable, FalseContent: Sendable {

}

extension ConditionalContent: Equatable where TrueContent: Equatable, FalseContent: Equatable {
    public static func == (lhs: ConditionalContent<TrueContent, FalseContent>, rhs: ConditionalContent<TrueContent, FalseContent>) -> Bool {
        switch (lhs.storage, rhs.storage) {
        case (.trueContent(let lhs), .trueContent(let rhs)):
            return lhs == rhs
        case (.falseContent(let lhs), .falseContent(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
