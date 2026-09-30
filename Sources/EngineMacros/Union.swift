//
// Copyright (c) Nathan Tannar
//

import Foundation

/// A macro that adds case accessors to an enum.
///
/// For each case, an `is<Case>` property is generated. For cases with associated
/// values, an optional property is generated for each associated value, which returns
/// `nil` when the enum is a different case. When any case has associated values, a
/// `CaseKey` enum and a `key` property are also generated.
///
/// Accessors are named after the case. Cases with multiple associated values also get
/// an accessor per value, named after the label or type, such as `pairInt` for
/// `case pair(int: Int, Double)`. If the type name is not a simple identifier or is
/// ambiguous, the position is used instead, such as `pair0` and `pair1` for
/// `case pair(Int, Int)`.
///
/// Setting an accessor behaves as follows:
/// - `is<Case>` switches to the case when set to `true`. It is read-only for cases
///   with associated values.
/// - The accessor for a case with a single associated value, or the tuple accessor for
///   a case with multiple associated values, switches to the case. Setting `nil` is
///   ignored, unless all the associated values are optional.
/// - The accessor for one value of a case with multiple associated values only updates
///   that value when the enum is already that case. Setting `nil` is ignored, unless
///   the value is optional.
///
/// Members already declared in the enum are not generated, so they can be customized.
/// A warning is emitted when an accessor is skipped because its name collides with
/// another case or generated accessor.
///
///     @Union
///     enum Content {
///         case empty
///         case text(String)
///     }
///
///     var content = Content.text("Hello")
///     content.isText // true
///     content.text // "Hello"
///     content.isEmpty = true // content == .empty
///
@attached(member, names: arbitrary)
public macro Union() = #externalMacro(module: "EngineMacrosCore", type: "UnionMacro")
