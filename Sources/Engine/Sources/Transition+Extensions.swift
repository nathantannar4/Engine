//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Transition {

    @inlinable
    public static func asymmetric<Insertion: Transition, Removal: Transition>(
        insertion: Insertion,
        removal: Removal
    ) -> AsymmetricTransition<Insertion, Removal> where Self == AsymmetricTransition<Insertion, Removal> {
        AsymmetricTransition(insertion: insertion, removal: removal)
    }
}


@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension View {

    @inlinable
    public func apply<T: Transition>(
        _ transition: T,
        phase: TransitionPhase
    ) -> some View {
        transition.apply(content: self, phase: phase)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@frozen
public struct AsymmetricTransition<
    Insertion: Transition,
    Removal: Transition
>: Transition {

    public var insertion: Insertion
    public var removal: Removal

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
