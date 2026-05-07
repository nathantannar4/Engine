//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View {

    @inlinable
    @_disfavoredOverload
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use `mask(alignment:content:)` instead.")
      @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use `mask(alignment:content:)` instead.")
      @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use `mask(alignment:content:)` instead.")
      @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use `mask(alignment:content:)` instead.")
      @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Use `mask(alignment:content:)` instead.")
    public func mask<Mask: View>(
        alignment: Alignment,
        @ViewBuilder mask: () -> Mask
    ) -> some View {
        self.mask(
            ZStack(
                alignment: alignment,
                content: mask
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        )
    }

    @inlinable
    @_disfavoredOverload
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
      @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
      @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
      @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
      @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
    public func overlay<Overlay: View>(
        alignment: Alignment,
        @ViewBuilder overlay: () -> Overlay
    ) -> some View {
        self.overlay(
            ZStack(
                alignment: alignment,
                content: overlay
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        )
    }

    @inlinable
    @_disfavoredOverload
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use `background(alignment:content:)` instead.")
      @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use `background(alignment:content:)` instead.")
      @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use `background(alignment:content:)` instead.")
      @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use `background(alignment:content:)` instead.")
      @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Use `background(alignment:content:)` instead.")
    public func background<Background: View>(
        alignment: Alignment,
        @ViewBuilder background: () -> Background
    ) -> some View {
        self.background(
            ZStack(
                alignment: alignment,
                content: background
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        )
    }
}

struct ViewExtensions_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                Color.blue
                    .mask(alignment: .bottom) {
                        Text("Hello, World")
                    }

                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    Color.blue
                        .mask(alignment: .bottom) {
                            Text("Hello, World")
                        }
                }
            }

            HStack {
                Color.blue
                    .overlay(alignment: .bottom) {
                        Text("Hello, World")
                    }

                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    Color.blue
                        .overlay(alignment: .bottom) {
                            Text("Hello, World")
                        }
                }
            }

            HStack {
                Color.blue
                    .opacity(0.3)
                    .background(alignment: .bottom) {
                        Text("Hello, World")
                    }

                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    Color.blue
                        .opacity(0.3)
                        .background(alignment: .bottom) {
                            Text("Hello, World")
                        }
                }
            }
        }
    }
}
