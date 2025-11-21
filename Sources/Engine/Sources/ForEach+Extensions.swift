//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension ForEach {

    @inlinable
    public init(
        _ count: Int,
        @ViewBuilder content: () -> Content
    ) where Data == Range<Int>, ID == Int, Content: View {
        let content = content()
        self.init(0..<count, id: \.self) { _ in
            content
        }
    }

    @inlinable
    public init(
        _ range: ClosedRange<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) where Data == ClosedRange<Int>, ID == Int, Content: View {
        self.init(range, id: \.self) { index in
            content(index)
        }
    }

    @_disfavoredOverload
    @inlinable
    public init<_Data: RandomAccessCollection>(
        _ data: _Data,
        @ViewBuilder content: @escaping (_Data.Index, _Data.Element) -> Content
    ) where Data == Array<(_Data.Index, _Data.Element)>, ID == _Data.Index, Content: View {
        let elements = Array(zip(data.indices, data))
        self.init(elements, id: \.0) { index, element in
            content(index, element)
        }
    }

    @inlinable
    public init<
        _Data: RandomAccessCollection
    >(
        _ data: _Data,
        id: KeyPath<_Data.Element, ID>,
        @ViewBuilder content: @escaping (_Data.Index, _Data.Element) -> Content
    ) where Data == Array<(_Data.Index, _Data.Element)>, Content: View {
        let elements = Array(zip(data.indices, data))
        let elementPath: KeyPath<(_Data.Index, _Data.Element), _Data.Element> = \.1
        self.init(elements, id: elementPath.appending(path: id)) { index, element in
            content(index, element)
        }
    }

    @inlinable
    public init<
        _Data: RandomAccessCollection
    >(
        _ data: _Data,
        @ViewBuilder content: @escaping (_Data.Index, _Data.Element) -> Content
    ) where Data == Array<(_Data.Index, _Data.Element)>, _Data.Element: Identifiable, ID == _Data.Element.ID, Content: View {
        let elements = Array(zip(data.indices, data))
        self.init(elements, id: \.1.id) { index, element in
            content(index, element)
        }
    }
}

// MARK: - ForEach Previews

struct ForEach_Previews: PreviewProvider {

    struct Model: Identifiable {
        var id = UUID().uuidString
    }

    static var previews: some View {
        VStack {
            ForEach(2) {
                Text("Hello, World")
            }

            ForEach(0) {
                Text("Hello, World")
            }

            ForEach([10, 20, 30]) { index, number in
                Text("\(index): \(number)")
            }

            ForEach([10, 20, 30], id: \.self) { index, number in
                Text("\(index): \(number)")
            }

            ForEach([Model()]) { index, model in
                Text("\(index): \(model.id)")
            }
        }
    }
}
