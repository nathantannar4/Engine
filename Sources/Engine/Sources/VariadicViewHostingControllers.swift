//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

/// A collection of hosting controllers that are generated from a ``VariadicView``
public struct VariadicViewHostingControllers<
    ID: Hashable,
    Modifier: VariadicViewElementModifier
>: RandomAccessCollection, Sequence {

    public typealias Content = VariadicViewElementBody<ID, Modifier>
    public typealias ViewControllerType = HostingController<Content>

    private struct StorageElement: Equatable {
        var id: ID?
        var viewController: ViewControllerType
    }
    private var elements: [StorageElement] = []
    private var modifier: Modifier
    private var makeHostingController: (@MainActor (Content) -> ViewControllerType)?

    public var viewControllers: [ViewControllerType] {
        elements.map({ $0.viewController })
    }

    public init(
        id: ID.Type = ID.self,
        makeHostingController: (@MainActor (Content) -> ViewControllerType)? = nil
    ) where Modifier == VariadicViewElementEmptyModifier {
        self.init(
            id: id,
            modifier: VariadicViewElementEmptyModifier(),
            makeHostingController: makeHostingController
        )
    }

    public init(
        id: ID.Type = ID.self,
        modifier: Modifier,
        makeHostingController: (@MainActor (Content) -> ViewControllerType)? = nil
    ) {
        self.modifier = modifier
        self.makeHostingController = makeHostingController
    }

    // MARK: - Selection

    public func viewController(for id: ID) -> PlatformViewController? {
        elements.first(where: { $0.id == id })?.viewController
    }

    public func index(for id: ID) -> Index? {
        elements.firstIndex(where: { $0.id == id })
    }

    public func id(for index: Index) -> ID? {
        elements[index].id
    }

    /// Returns `true` if any of the underlying view controllers were added or removed
    @discardableResult
    @MainActor
    public mutating func updateViewControllers(
        selected: ID? = nil,
        content: VariadicView,
        transaction: Transaction,
        update: (Int, ViewControllerType, VariadicView.Element) -> Void = { _, _, _ in }
    ) -> Bool {
        var elements = elements
        elements.reserveCapacity(content.count)
        let remaining = elements.count - content.count
        if remaining > 0 {
            elements.removeLast(remaining)
        }

        for (index, child) in content.enumerated() {
            let id = child.selection(as: ID.self)
            let content = VariadicViewElementBody(
                element: child,
                modifier: modifier,
                selection: selected
            )
            if elements.count > index {
                if elements[index].viewController.content.element.id == child.id {
                    elements[index].viewController.update(content: content, transaction: transaction)
                } else {
                    let hostingController = initHostingController(content: content)
                    elements[index] = StorageElement(
                        id: id,
                        viewController: hostingController
                    )
                }
            } else {
                let hostingController = initHostingController(content: content)
                let element = StorageElement(
                    id: id,
                    viewController: hostingController
                )
                elements.append(element)
            }
            update(index, elements[index].viewController, child)
        }

        if self.elements != elements {
            self.elements = elements
            return true
        }
        return false
    }

    @MainActor
    private func initHostingController(content: Content) -> ViewControllerType {
        if let makeHostingController {
            return makeHostingController(content)
        }
        let hostingController = HostingController(
            content: content
        )
        #if os(iOS) || os(tvOS) || os(visionOS)
        hostingController.view.backgroundColor = nil
        #else
        hostingController.view.layer?.backgroundColor = nil
        #endif
        return hostingController
    }

    // MARK: Sequence

    public typealias Iterator = IndexingIterator<Array<ViewControllerType>>

    public nonisolated func makeIterator() -> Iterator {
        viewControllers.makeIterator()
    }

    public nonisolated var underestimatedCount: Int {
        viewControllers.underestimatedCount
    }

    // MARK: RandomAccessCollection

    public typealias Element = ViewControllerType
    public typealias Index = Int

    public nonisolated var startIndex: Index {
        viewControllers.startIndex
    }

    public nonisolated var endIndex: Index {
        viewControllers.endIndex
    }

    public nonisolated subscript(position: Index) -> Element {
        viewControllers[position]
    }

    public nonisolated func index(after index: Index) -> Index {
        viewControllers.index(after: index)
    }
}

#endif
