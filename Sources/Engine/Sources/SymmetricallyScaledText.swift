//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct SymmetricallyScaledText: View {
    @usableFromInline
    var source: Text
    @usableFromInline
    var reference: Text

    @inlinable
    public init(source: Text, reference: Text) {
        self.source = source
        self.reference = reference
    }

    @inlinable
    public init(source: LocalizedStringKey, reference: LocalizedStringKey) {
        self.init(source: Text(source), reference: Text(reference))
    }

    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(source: S, reference: S) {
        self.init(source: Text(source), reference: Text(reference))
    }

    public var body: some View {
        _SymmetricallyScaledText(source: source, reference: reference)
    }
}

// MARK: - Previews

struct SymmetricallyScaledText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let topText = Text("Hello, World")
            let bottomText = Text("Lorem ipsum dolor sit amet consectetur adipiscing elit")
            VStack {
                topText
                bottomText
            }

            VStack {
                SymmetricallyScaledText(
                    source: topText,
                    reference: bottomText
                )

                SymmetricallyScaledText(
                    source: bottomText,
                    reference: topText
                )
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(width: 200)
        }
    }
}
