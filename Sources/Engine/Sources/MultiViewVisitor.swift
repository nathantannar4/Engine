//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``ViewVisitor`` allows for `some View` to be unwrapped
/// to visit the concrete `View` type.
public typealias MultiViewVisitor = EngineCore.MultiViewVisitor

/// The ``TypeDescriptor`` for the `MultiView` protocol
public typealias MultiViewProtocolDescriptor = EngineCore.MultiViewProtocolDescriptor
