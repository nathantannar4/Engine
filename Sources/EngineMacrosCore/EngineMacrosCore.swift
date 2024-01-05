//
// Copyright (c) Nathan Tannar
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EngineMacrosCore: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StyledViewMacro.self
    ]
}
