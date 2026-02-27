//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding: @retroactive ExpressibleByNilLiteral where Value: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = .constant(nil)
    }
}

// MARK: - Previews

struct Binding_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OptionalBindingPreview(value: nil)
            OptionalBindingPreview(value: .constant(nil))
        }
    }

    struct OptionalBindingPreview: View {
        @Binding var value: Int?

        var body: some View {
            Text(value?.description ?? "nil")
        }
    }
}
