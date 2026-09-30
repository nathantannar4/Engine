//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension RedactionReasons {

    /// Displayed data should be hidden from screen captures, such as
    /// screenshots and screen recordings.
    public static let screencaptureHidden = RedactionReasons(rawValue: 1 << 3)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
/// A modifier that marks a view as privacy sensitive and redacts it with
/// the ``SwiftUI/RedactionReasons/screencaptureHidden`` reason.
@frozen
public struct ScreenCaptureHiddenModifier: ViewModifier {

    /// Whether the content should be hidden from screen captures.
    public var isHidden: Bool

    /// Creates a modifier that hides content from screen captures when `isHidden` is `true`.
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

    /// Hides this view from screen captures, such as screenshots and screen
    /// recordings, by marking it as privacy sensitive and redacting it with
    /// the ``SwiftUI/RedactionReasons/screencaptureHidden`` reason.
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
