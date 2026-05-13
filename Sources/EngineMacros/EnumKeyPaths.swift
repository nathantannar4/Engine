//
// Copyright (c) Nathan Tannar
//

import Foundation

@attached(member, names: arbitrary)
public macro EnumKeyPaths() = #externalMacro(module: "EngineMacrosCore", type: "EnumKeyPathMacro")
