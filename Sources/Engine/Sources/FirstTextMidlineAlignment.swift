//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension VerticalAlignment {
    private enum FirstTextMidlineAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            let dy = context[.lastTextBaseline] - context[.firstTextBaseline]
            let lineHeight = context.height - dy
            return lineHeight / 2
        }
    }

    public static let firstTextMidline = VerticalAlignment(FirstTextMidlineAlignment.self)
}

// MARK: - Previews

struct FirstTextMidlineAlignment_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack(alignment: .firstTextMidline) {
                Color.red
                    .frame(width: 32, height: 32)

                Text("Lorem ipsum")
            }

            HStack(alignment: .firstTextMidline) {
                Color.red
                    .frame(width: 32, height: 32)

                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
            }
        }
    }
}
