//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// An ``EnvironmentKeyVisitor`` allows for `some EnvironmentKey` to be unwrapped
/// to visit the concrete `EnvironmentKey` type.
public typealias EnvironmentKeyVisitor = EngineCore.EnvironmentKeyVisitor

/// The ``TypeDescriptor`` for the `EnvironmentKey` protocol
public typealias EnvironmentKeyProtocolDescriptor = EngineCore.EnvironmentKeyProtocolDescriptor
