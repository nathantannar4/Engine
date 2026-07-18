//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Applies the transaction when enabled and the value changes
@frozen
public struct TransactionModifier<Value: Equatable>: VersionedViewModifier {

    public var transaction: Transaction
    public var value: Value
    public var isEnabled: Bool

    @inlinable
    public init(
        transaction: Transaction,
        value: Value,
        isEnabled: Bool = true
    ) {
        self.transaction = transaction
        self.value = value
        self.isEnabled = isEnabled
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .transaction(
                value: TriggerValue(
                    value: value,
                    isEnabled: isEnabled
                )
            ) { value in
                value = transaction
            }
    }

    private struct _V1Modifier: ViewModifier {
        var newValue: TriggerValue
        var transaction: Transaction

        @State var oldValue: TriggerValue

        init(
            transaction: Transaction,
            value: TriggerValue
        ) {
            self.newValue = value
            self.transaction = transaction
            self._oldValue = State(wrappedValue: value)
        }

        func body(content: Content) -> some View {
            content
                .transaction { value in
                    guard oldValue != newValue else { return }
                    oldValue = newValue
                    value = transaction
                }
        }
    }
    public func v1Body(content: Content) -> some View {
        content
            .modifier(
                _V1Modifier(
                    transaction: transaction,
                    value: TriggerValue(
                        value: value,
                        isEnabled: isEnabled
                    )
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
    public func transaction<Value: Equatable>(
        _ transaction: Transaction,
        value: Value,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            TransactionModifier(
                transaction: transaction,
                value: value,
                isEnabled: isEnabled
            )
        )
    }
}

// MARK: - Previews

struct TransactionModifier_Previews: PreviewProvider {

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
                    .transaction(Transaction(animation: .default), value: flag, isEnabled: isEnabled)

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
