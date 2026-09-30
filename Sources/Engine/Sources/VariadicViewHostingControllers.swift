//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

/// A collection of hosting controllers that are generated from the subviews of a ``VariadicView``.
open class VariadicViewHostingControllersAdapter<
    ID: Hashable,
    Modifier: VariadicViewElementModifier
>: RandomAccessCollection, Sequence {

    /// The content of each hosting controller.
    public typealias Content = VariadicViewElementBody<ID, Modifier>
    /// The type of each hosting controller.
    public typealias ViewControllerType = HostingController<Content>

    private struct StorageElement: Equatable {
        var id: ID?
        var viewController: ViewControllerType
    }
    private var elements: [StorageElement] = []
    private var modifier: Modifier

    /// The hosting controllers, one for each subview.
    public var viewControllers: [ViewControllerType] {
        elements.map({ $0.viewController })
    }

    /// Creates an adapter whose subviews are identified by a selection value of type `ID`.
    public convenience init(
        id: ID.Type = ID.self
    ) where Modifier == VariadicViewElementEmptyModifier {
        self.init(
            id: id,
            modifier: VariadicViewElementEmptyModifier()
        )
    }

    /// Creates an adapter whose subviews are identified by a selection value of type `ID`,
    /// and modified by `modifier`.
    public init(
        id: ID.Type = ID.self,
        modifier: Modifier
    ) {
        self.modifier = modifier
    }

    // MARK: - Selection

    /// Returns the hosting controller for the subview with the selection value `id`.
    public func viewController(for id: ID) -> PlatformViewController? {
        elements.first(where: { $0.id == id })?.viewController
    }

    /// Returns the index of the subview with the selection value `id`.
    public func index(for id: ID) -> Index? {
        elements.firstIndex(where: { $0.id == id })
    }

    /// Returns the index of the subview hosted by `viewController`.
    public func index(for viewController: PlatformViewController) -> Index? {
        elements.firstIndex(where: { $0.viewController == viewController })
    }

    /// Returns the selection value of the subview at `index`.
    public func id(for index: Index) -> ID? {
        elements[index].id
    }

    /// Returns the selection value of the subview hosted by `viewController`.
    public func id(for viewController: PlatformViewController) -> ID? {
        guard let index = index(for: viewController) else { return nil }
        return id(for: index)
    }

    /// Makes the hosting controller for a subview.
    ///
    /// Override to customize the hosting controller. The default implementation
    /// clears the background color of the hosting controller's view.
    @MainActor
    open func makeHostingController(content: Content) -> ViewControllerType {
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

    /// Updates the hosting controllers to match the subviews of `content`.
    ///
    /// Hosting controllers are reused when the subview at the same index has the
    /// same identity, otherwise a new hosting controller is made.
    ///
    /// - Parameters:
    ///   - selected: The currently selected value.
    ///   - content: The subviews to host.
    ///   - transaction: The transaction used to update existing hosting controllers.
    ///   - update: A closure called for each subview with its index and hosting controller.
    /// - Returns: `true` if any of the underlying view controllers were added, removed or replaced.
    @discardableResult
    @MainActor
    open func updateViewControllers(
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
                    let hostingController = makeHostingController(content: content)
                    elements[index] = StorageElement(
                        id: id,
                        viewController: hostingController
                    )
                }
            } else {
                let hostingController = makeHostingController(content: content)
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
