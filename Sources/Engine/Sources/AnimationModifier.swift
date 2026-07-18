//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Applies the animation when enabled and the value changes
@frozen
public struct AnimationModifier<Value: Equatable>: ViewModifier {

    public var animation: Animation?
    public var value: Value
    public var isEnabled: Bool

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

/// Applies the animation to the transaction if it does not have an animation
@frozen
public struct OptionalAnimationModifier<Value: Equatable>: VersionedViewModifier {

    public var animation: Animation?
    public var value: Value

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
                if value.animation == nil, !value.disablesAnimations {
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
                    guard !value.disablesAnimations, oldValue != newValue else { return }
                    oldValue = newValue
                    if value.animation == nil {
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
