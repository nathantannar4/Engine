//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

struct VariadicViewExamples: View {
    var body: some View {
        BulletList {
            ForEach(1...3, id: \.self) { i in
                Text("View \(i)")
            }
        }

        FruitPicker()
    }
}

struct BulletList<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VariadicViewAdapter {
            content
        } content: { source in
            ForEachSubview(source) { index, subview in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(index + 1).")

                    subview
                }
            }
        }
    }
}

enum Fruit: String, Hashable, CaseIterable {
    case apple
    case orange
    case banana
}

struct FruitPicker: View {
    @State var selection: Fruit = .apple

    var body: some View {
        PickerView(selection: $selection) {
            ForEach(Fruit.allCases, id: \.self) { fruit in
                Text(fruit.rawValue)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PickerView<Selection: Hashable, Content: View>: View {
    @Binding var selection: Selection
    @ViewBuilder var content: Content

    var body: some View {
        VariadicViewAdapter {
            content
        } content: { source in
            ForEachSubview(source) { index, subview in
                HStack {
                    // This works since the ForEach ID is the Fruit (ie Selection) type
                    let isSelected: Bool = selection == subview.id(as: Selection.self)
                    if isSelected {
                        Image(systemName: "checkmark")
                    }

                    Button {
                        selection = subview.id(as: Selection.self)!
                    } label: {
                        subview
                    }
                }
            }
        }
    }
}

struct VariadicViewExamples_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VariadicViewExamples()
        }
    }
}
