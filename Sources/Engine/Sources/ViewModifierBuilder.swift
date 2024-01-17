//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `ViewModifier` from closures.
@resultBuilder
public struct ViewModifierBuilder {

    @_alwaysEmitIntoClient
    public static func buildBlock() -> EmptyModifier {
        EmptyModifier()
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<Modifier: ViewModifier>(
        _ modifier: Modifier
    ) -> Modifier {
        modifier
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<
        M0: ViewModifier,
        M1: ViewModifier
    >(
        _ m0: M0,
        _ m1: M1
    ) -> ModifiedContent<M0, M1> {
        m0.concat(m1)
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<
        M0: ViewModifier,
        M1: ViewModifier,
        M2: ViewModifier
    >(
        _ m0: M0,
        _ m1: M1,
        _ m2: M2
    ) -> ModifiedContent<ModifiedContent<M0, M1>, M2> {
        m0.concat(m1).concat(m2)
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<
        M0: ViewModifier,
        M1: ViewModifier,
        M2: ViewModifier,
        M3: ViewModifier
    >(
        _ m0: M0,
        _ m1: M1,
        _ m2: M2,
        _ m3: M3
    ) -> ModifiedContent<ModifiedContent<ModifiedContent<M0, M1>, M2>, M3> {
        m0.concat(m1).concat(m2).concat(m3)
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<
        M0: ViewModifier,
        M1: ViewModifier,
        M2: ViewModifier,
        M3: ViewModifier,
        M4: ViewModifier
    >(
        _ m0: M0,
        _ m1: M1,
        _ m2: M2,
        _ m3: M3,
        _ m4: M4
    ) -> ModifiedContent<ModifiedContent<ModifiedContent<ModifiedContent<M0, M1>, M2>, M3>, M4> {
        m0.concat(m1).concat(m2).concat(m3).concat(m4)
    }
}

extension View {
    public func modifier<Modifier: ViewModifier>(
        @ViewModifierBuilder modifier: () -> Modifier
    ) -> ModifiedContent<Self, Modifier> {
        self.modifier(modifier())
    }
}
