//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// An `AlignmentID` that is resolved from multiple values
///
/// > Tip: Use ``VariadicAlignmentID`` to create alignments
/// similar to `.firstTextBaseline`
public protocol VariadicAlignmentID: AlignmentID {
    static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat)
}

extension VariadicAlignmentID {

    public static func _combineExplicit(
        childValue: CGFloat,
        _ n: Int,
        into parentValue: inout CGFloat?
    ) {
        reduce(value: &parentValue, n: n, nextValue: childValue)
    }
}

// MARK: - Previews

extension VerticalAlignment {
    struct SecondTextBaseline: VariadicAlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.firstTextBaseline]
        }

        static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat) {
            if n == 1 {
                value = nextValue
            }
        }
    }

    static let secondTextBaseline = VerticalAlignment(SecondTextBaseline.self)
}

struct VariadicAlignmentID_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 48) {
            HStack(alignment: .firstTextBaseline) {
                Text("Label")

                VStack(alignment: .trailing) {
                    Text("One")
                    Text("Two")
                    Text("Three")
                }
                .font(.title)
            }

            HStack(alignment: .secondTextBaseline) {
                Text("Label")

                VStack(alignment: .trailing) {
                    Text("One")
                        .alignmentGuide(.secondTextBaseline) { d in
                            d[VerticalAlignment.firstTextBaseline]
                        }

                    Text("Two")
                        .alignmentGuide(.secondTextBaseline) { d in
                            d[VerticalAlignment.firstTextBaseline]
                        }

                    Text("Three")
                        .alignmentGuide(.secondTextBaseline) { d in
                            d[VerticalAlignment.firstTextBaseline]
                        }
                }
                .font(.title)
            }
        }
    }
}
