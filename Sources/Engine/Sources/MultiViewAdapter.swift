//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

/// A view that wraps `Content` in a multi view.
///
/// Most views such as `ZStack`, `VStack` and `HStack` are
/// unary views. This means they would produce a single subview
/// if transformed by a ``VariadicViewAdapter``. This is contrary
/// to `TupleView` and `Group` which would produce multiple
/// subviews. This different in behaviour can be crucial, as it impacts:
/// layout, how a view is modified by a `ViewModifier`, and
/// performance.
///
/// > Tip: In most cases you shouldn't need to use ``MultiViewAdapter``,
/// but it can be used to ensure you're working with a multi view.
///
/// With ``MultiViewAdapter`` the individual views can be accessed
/// by an index. This can be particularly useful when you need to transform a
/// collection of views to a `UIViewController` when bridging to UIKit
/// components.
///
@frozen
public struct MultiViewAdapter<Content>: View, RandomAccessCollection {

    @usableFromInline
    var content: TupleView<Content>

    @inlinable
    public init(@ViewBuilder content: () -> TupleView<Content>) {
        self.content = content()
    }

    @_disfavoredOverload
    @inlinable
    public init(@ViewBuilder content: () -> Content) where Content: View {
        self.content = TupleView(content())
    }

    // MARK: Collection

    public typealias Element = Any
    public typealias Iterator = IndexingIterator<Array<Element>>
    public typealias Index = Int

    public func makeIterator() -> Iterator {
        indices.map { self[$0] }.makeIterator()
    }

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        swift_getTupleCount(content.value) ?? 1
    }

    public subscript(position: Index) -> Element {
        var element = swift_getTupleElement(position, content.value)
        if element == nil, position == 0 {
            element = content.value
        }
        precondition(element != nil, "Index out of range")
        return element!
    }

    public func index(after index: Index) -> Index {
        index + 1
    }

    // MARK: View

    public var body: Never {
        bodyError()
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        TupleView<Content>._makeView(view: view[\.content], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        TupleView<Content>._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        TupleView<Content>._viewListCount(inputs: inputs)
    }
}
