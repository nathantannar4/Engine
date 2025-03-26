//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding {

    /// A ``BindingTransform`` that transforms the value to `true` when `nil`
    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        self[keyPath: \.isNone]
    }
}


extension Optional {

    @usableFromInline
    var isNone: Bool {
        get { self == nil }
        set {
            if newValue {
                self = .none
            }
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IsNilTransform_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value: String?
        @State var update = 0

        var body: some View {
            VStack {
                ToggleView(isNil: $value.isNil())

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
            @Binding var isNil: Bool
            var body: some View {
                Self._printChanges()
                return Toggle(isOn: $isNil) { EmptyView() }
                    .labelsHidden()
            }
        }
    }
}
