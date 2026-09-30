//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension Transition {

    /// Returns a transition that uses `insertion` when the view is inserted and
    /// `removal` when the view is removed.
    @inlinable
    public static func asymmetric<Insertion: Transition, Removal: Transition>(
        insertion: Insertion,
        removal: Removal
    ) -> AsymmetricTransition<Insertion, Removal> where Self == AsymmetricTransition<Insertion, Removal> {
        AsymmetricTransition(insertion: insertion, removal: removal)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension TransitionPhase {

    /// The progress of the transition, which is `1` when the phase is the identity
    /// and `0` otherwise.
    @inlinable
    public var progress: CGFloat {
        isIdentity ? 1 : 0
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension View {

    /// Applies `transition` to the view for the given phase.
    @inlinable
    public func apply<T: Transition>(
        _ transition: T,
        phase: TransitionPhase
    ) -> some View {
        transition.apply(content: self, phase: phase)
    }
}

/// A composite `Transition` that uses a different transition for insertion
/// versus removal.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@frozen
public struct AsymmetricTransition<
    Insertion: Transition,
    Removal: Transition
>: Transition {

    /// The transition used when the view is inserted.
    public var insertion: Insertion
    /// The transition used when the view is removed.
    public var removal: Removal

    /// Creates a transition that uses `insertion` when the view is inserted and
    /// `removal` when the view is removed.
    @inlinable
    public init(
        insertion: Insertion,
        removal: Removal
    ) {
        self.insertion = insertion
        self.removal = removal
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .apply(insertion, phase: phase == .willAppear ? phase : .identity)
            .apply(removal, phase: phase == .didDisappear ? phase : .identity)
    }
}
