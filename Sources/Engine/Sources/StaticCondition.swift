//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A statically defined condition
///
/// > Important: The evaluation result should be static
///
public protocol StaticCondition {
    static var value: Bool { get }
}

@frozen
public enum TrueStaticCondition: StaticCondition {
    public static let value: Bool = true
}

@frozen
public enum FalseStaticCondition: StaticCondition {
    public static let value: Bool = false
}

/// A `StaticCondition` that compares types
@frozen
public enum IsEqual<LHS, RHS>: StaticCondition {
    @inlinable
    public static var value: Bool {
        LHS.self == RHS.self
    }
}

// MARK: - Previews

struct StaticCondition_Previews: PreviewProvider {

    struct Preview<Condition: StaticCondition>: View {

        var content: String

        init(enabled content: String) where Condition == TrueStaticCondition {
            self.content = content
        }

        init(disabled content: String) where Condition == FalseStaticCondition {
            self.content = content
        }

        var body: some View {
            StaticConditionalContent(Condition.self) {
                Text(content)
                    .background(Color.green)
            } otherwise: {
                Text(content)
                    .background(Color.red)
            }
        }
    }

    static var previews: some View {
        VStack {
            StaticConditionalContent(TrueStaticCondition.self) {
                Text("Enabled")
            } otherwise: {
                Text("Disabled")
            }

            StaticConditionalContent(FalseStaticCondition.self) {
                Text("Enabled")
            } otherwise: {
                Text("Disabled")
            }

            Preview(enabled: "On")

            Preview(disabled: "Off")
        }
    }
}
