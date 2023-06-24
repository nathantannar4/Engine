//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A ``MultiViewVisitor`` allows for `some View` to be unwrapped
/// to visit the concrete `View` type for each subview.
public typealias MultiViewVisitor = EngineCore.MultiViewVisitor

/// The ``TypeDescriptor`` for the ``MultiView`` protocol
public typealias MultiViewProtocolDescriptor = EngineCore.MultiViewProtocolDescriptor
