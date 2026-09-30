//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Applies the animation when enabled and the value changes
///
/// Toggling `isEnabled` is also treated as a change of the value.
@frozen
public struct AnimationModifier<Value: Equatable>: ViewModifier {

    /// The animation to apply.
    public var animation: Animation?
    /// The value to monitor for changes.
    public var value: Value
    /// A Boolean value that indicates whether changes to `value` are animated.
    public var isEnabled: Bool

    /// Creates a modifier that applies `animation` when `value` changes and `isEnabled` is `true`.
    @inlinable
    public init(
        animation: Animation?,
        value: Value,
        isEnabled: Bool = true
    ) {
        self.animation = animation
        self.value = value
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .animation(
                animation,
                value: TriggerValue(
                    value: value,
                    isEnabled: isEnabled
                )
            )
    }

    private struct TriggerValue: Equatable {
        var value: Value
        var isEnabled: Bool

        static func == (lhs: TriggerValue, rhs: TriggerValue) -> Bool {
            guard lhs.isEnabled, rhs.isEnabled else {
                return lhs.isEnabled == rhs.isEnabled
            }
            return lhs.value == rhs.value
        }
    }
}

extension View {

    /// Applies the given animation to this view when the specified value changes
    /// and `isEnabled` is `true`.
    ///
    /// See ``AnimationModifier``.
    @inlinable
    public func animation<Value: Equatable>(
        _ animation: Animation?,
        value: Value,
        isEnabled: Bool
    ) -> some View {
        modifier(
            AnimationModifier(
                animation: animation,
                value: value,
                isEnabled: isEnabled
            )
        )
    }
}

/// Applies the animation to the transaction when the value changes, if the transaction does not
/// have an animation or has the default animation, and animations are not disabled
@frozen
public struct OptionalAnimationModifier<Value: Equatable>: VersionedViewModifier {

    /// The animation to apply.
    public var animation: Animation?
    /// The value to monitor for changes.
    public var value: Value

    /// Creates a modifier that applies `animation` when `value` changes.
    @inlinable
    public init(
        animation: Animation?,
        value: Value
    ) {
        self.animation = animation
        self.value = value
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .transaction(
                value: value
            ) { value in
                if !value.disablesAnimations, value.animation == nil || value.animation == .default {
                    value.animation = animation
                }
            }
    }

    private struct _V1Modifier: ViewModifier {
        var newValue: Value
        var animation: Animation?

        @State var oldValue: Value

        init(
            animation: Animation? = nil,
            value: Value
        ) {
            self.newValue = value
            self.animation = animation
            self._oldValue = State(wrappedValue: value)
        }

        func body(content: Content) -> some View {
            content
                .transaction { value in
                    guard oldValue != newValue else { return }
                    oldValue = newValue
                    if !value.disablesAnimations, value.animation == nil || value.animation == .default {
                        value.animation = animation
                    }
                }
        }
    }
    public func v1Body(content: Content) -> some View {
        content
            .modifier(
                _V1Modifier(
                    animation: animation,
                    value: value
                )
            )
    }
}


// MARK: - Previews

struct AnimationModifier_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false
        @State var isEnabled = false

        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(flag ? Color.blue : Color.red)
                    .frame(width: 100, height: 100)
                    .animation(.default, value: flag, isEnabled: isEnabled)

                Button {
                    flag.toggle()
                } label: {
                    Text("Trigger")
                }

                Toggle(isOn: $isEnabled) {
                    Text("isEnabled")
                }
            }
        }
    }
}
