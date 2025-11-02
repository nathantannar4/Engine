//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
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
                .ignoresSafeArea()
                .overlay(
                    mask()
                        .blendMode(.destinationOut),
                    alignment: alignment
                )
        )
    }
}
