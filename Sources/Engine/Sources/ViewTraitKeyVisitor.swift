//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``ViewTraitKeyVisitor`` allows for `some _ViewTraitKey` to be unwrapped
/// to visit the concrete `_ViewTraitKey` type.
public typealias ViewTraitKeyVisitor = EngineCore.ViewTraitKeyVisitor

/// The ``TypeDescriptor`` for the `_ViewTraitKey` protocol
public typealias ViewTraitKeyProtocolDescriptor = EngineCore.ViewTraitKeyProtocolDescriptor
