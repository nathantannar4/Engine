//
// Copyright (c) Nathan Tannar
//

import Foundation

@attached(member, names: arbitrary)
public macro Union() = #externalMacro(module: "EngineMacrosCore", type: "UnionMacro")
