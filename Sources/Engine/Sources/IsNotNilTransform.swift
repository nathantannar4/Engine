//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding {

    /// A ``BindingTransform`` that transforms the value to `true` when not `nil`
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNotNone]
    }
}

extension Optional {

    @usableFromInline
    var isNotNone: Bool {
        get { self != nil }
        set {
            if !newValue {
                self = .none
            }
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IsNotNilTransform_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value: String?
        @State var update = 0

        var body: some View {
            VStack {
                ToggleView(isNotNil: $value.isNotNil())

                if let value {
                    Text(value)
                }

                Button {
                    value = "Hello, World"
                } label: {
                    Text("Add Text")
                }

                Button {
                    update += 1
                } label: {
                    Text("Render Update \(update)")
                }
            }
        }

        struct ToggleView: View {
            @Binding var isNotNil: Bool
            var body: some View {
                Self._printChanges()
                return Toggle(isOn: $isNotNil) { EmptyView() }
                    .labelsHidden()
            }
        }
    }
}
