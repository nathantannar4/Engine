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
