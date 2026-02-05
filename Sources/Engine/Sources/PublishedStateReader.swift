import SwiftUI

@frozen
public struct PublishedStateReader<Value, Content: View>: View {

    @PublishedState.Binding var value: Value
    var content: (Binding<Value>) -> Content

    public init(
        _ value: PublishedState<Value>.Binding,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = value
        self.content = content
    }

    public var body: some View {
        content($value)
    }
}

// MARK: - Previews

struct PublishedStateReader_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @PublishedState var value = 0

        var body: some View {
            VStack {
                Text(value.description)

                PublishedStateReader($value) { $value in
                    Text(value.description)
                }

                Button {
                    value += 1
                } label: {
                    Text("Increment")
                }
            }
        }
    }
}
