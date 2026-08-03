//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension RedactionReasons {

    public static let screencaptureHidden = RedactionReasons(rawValue: 1 << 3)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct ScreenCaptureHiddenModifier: ViewModifier {

    public var isHidden: Bool

    @inlinable
    public init(isHidden: Bool) {
        self.isHidden = isHidden
    }

    public func body(content: Content) -> some View {
        content
            .privacySensitive(isHidden)
            .redacted(reason: isHidden ? [.screencaptureHidden] : [])
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @inlinable
    public func screenCaptureHidden(_ isHidden: Bool = true) -> some View {
        modifier(ScreenCaptureHiddenModifier(isHidden: isHidden))
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RedactionReasons_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .screenCaptureHidden()

            HStack {
                Image(systemName: "apple.logo")

                Text("Hello, World")
            }
            .redacted(reason: .placeholder)
        }
    }
}
