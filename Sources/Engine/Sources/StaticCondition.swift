//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A statically defined condition
///
/// > Important: The evaluation result should be static
///
public protocol StaticCondition {
    static var value: Bool { get }
}

/// A `StaticCondition` that compares types
public enum IsEqual<LHS, RHS>: StaticCondition {
    public static var value: Bool {
        LHS.self == RHS.self
    }
}
