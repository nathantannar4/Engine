//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View {

    /// Masks this view using the inverted alpha channel of the given view.
    @inlinable
    public func invertedMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder mask: () -> Mask
    ) -> some View {
        self.mask(
            Rectangle()
                .scale(100)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    mask()
                        .blendMode(.destinationOut),
                    alignment: alignment
                )
        )
    }
}

// MARK: - Previews

struct InvertedMask_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Color.blue
                .frame(height: 50)
                .invertedMask {
                    Text("Hello, World")
                }

            Color.blue
                .frame(height: 50)
                .invertedMask(alignment: .bottomTrailing) {
                    Text("Hello, World")
                }
        }
        .padding()
    }
}
