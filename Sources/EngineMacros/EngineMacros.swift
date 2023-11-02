//
// Copyright (c) Nathan Tannar
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EngineMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StyledViewMacro.self
    ]
}
