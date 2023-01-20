//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``ViewModifierVisitor`` allows for `some ViewModifier` to be unwrapped
/// to visit the concrete `ViewModifier` type.
public typealias ViewModifierVisitor = EngineCore.ViewModifierVisitor

/// The ``TypeDescriptor`` for the `ViewModifier` protocol
public typealias ViewModifierProtocolDescriptor = EngineCore.ViewModifierProtocolDescriptor
