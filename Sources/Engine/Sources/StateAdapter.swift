//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct StateAdapter<Value, Content: View>: View {

    @State var value: Value

    var content: (Binding<Value>) -> Content

    public init(
        initialValue: Value,
        content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = State(wrappedValue: initialValue)
        self.content = content
    }

    public var body: some View {
        content($value)
    }
}

// MARK: - Previews

struct StateAdapter_Previews: PreviewProvider {
    static var previews: some View {
        StateAdapter(initialValue: 0) { $number in
            Button {
                number += 1
            } label: {
                Text(number.description)
            }
        }
    }
}
