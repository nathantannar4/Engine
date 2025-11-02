//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

#if !os(watchOS)

#if os(macOS)
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
public typealias PlatformViewControllerRepresentableProtocolDescriptor = NSViewControllerRepresentableProtocolDescriptor
public typealias PlatformViewController = NSViewController
extension PlatformViewControllerRepresentable {
    public typealias PlatformViewControllerType = NSViewControllerType
}
#else
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
public typealias PlatformViewControllerRepresentableProtocolDescriptor = UIViewControllerRepresentableProtocolDescriptor
public typealias PlatformViewController = UIViewController
extension UIViewControllerRepresentable {
    public typealias PlatformViewControllerType = UIViewControllerType
}
#endif

/// An adapter that converts a generic ``View`` into a view controller
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
@MainActor @preconcurrency
open class ViewControllerAdapter<
    Content: View,
    Representable: PlatformViewRepresentable
> {

    public var viewController: PlatformViewController!

    var context: Any!
    var conformance: ProtocolConformance<PlatformViewControllerRepresentableProtocolDescriptor>? = nil

    public init(
        content: Content,
        context: Representable.Context
    ) {
        if let conformance = PlatformViewControllerRepresentableProtocolDescriptor.conformance(of: Content.self) {
            self.conformance = conformance
            updateViewController(
                content: content,
                context: context
            )
        } else {
            viewController = makeHostingController(
                content: content,
                context: context
            )
        }
    }

    deinit {
        if let conformance {
            var visitor = Visitor(
                content: nil,
                context: nil,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
        }
    }

    // MARK: - Update

    public func updateViewController(
        content: Content,
        context: Representable.Context
    ) {
        if let conformance {
            var visitor = Visitor(
                content: content,
                context: context,
                adapter: self
            )
            conformance.visit(visitor: &visitor)
            updateViewController(context: context)
        } else {
            updateHostingController(
                content: content,
                context: context
            )
        }
    }

    // MARK: - Available Overrides

    open func makeHostingController(
        content: Content,
        context: Representable.Context
    ) -> PlatformViewController {
        return HostingController(content: content)
    }

    open func updateHostingController(
        content: Content,
        context: Representable.Context
    ) {
        let hostingController = viewController as! HostingController<Content>
        hostingController.content = content
    }

    open func transformViewControllerEnvironment(
        _ environment: inout EnvironmentValues
    ) {
    }

    open func updateViewController(
        context: Representable.Context
    ) {
    }

    // MARK: - ViewRepresentable

    private struct ContextLayout<Coordinator> {
        // Only `UIViewRepresentable` uses V4
        struct V4 {
            struct RepresentableContextValues {
                enum EnvironmentStorage {
                    case eager(EnvironmentValues)
                    case lazy(() -> EnvironmentValues)
                }
                var preferenceBridge: AnyObject?
                var transaction: Transaction
                var environmentStorage: EnvironmentStorage

                var environment: EnvironmentValues {
                    get {
                        switch environmentStorage {
                        case .eager(let environment):
                            return environment
                        case .lazy(let block):
                            return block()
                        }
                    }
                    set {
                        environmentStorage = .eager(newValue)
                    }
                }
            }

            var values: RepresentableContextValues
            var coordinator: Coordinator
        }

        struct V1 {
            var coordinator: Coordinator
            var transaction: Transaction
            var environment: EnvironmentValues
            var preferenceBridge: AnyObject?
        }
    }

    @MainActor
    private struct Visitor: @preconcurrency ViewVisitor {
        nonisolated(unsafe) var content: Content?
        nonisolated(unsafe) var context: Representable.Context?
        nonisolated(unsafe) var adapter: ViewControllerAdapter<Content, Representable>

        mutating func visit<_Content>(type: _Content.Type) where _Content: PlatformViewControllerRepresentable {
            guard
                let content = content.map({ unsafeBitCast($0, to: _Content.self) }),
                let bridgedContext = context
            else {
                if let context = adapter.context, let viewController = adapter.viewController as? _Content.PlatformViewControllerType {
                    func project<T>(_ value: T) {
                        let coordinator = unsafeBitCast(value, to: _Content.Context.self).coordinator
                        #if os(iOS) || os(tvOS) || os(visionOS)
                        _Content.dismantleUIViewController(viewController, coordinator: coordinator)
                        #elseif os(macOS)
                        _Content.dismantleNSViewController(viewController, coordinator: coordinator)
                        #endif
                    }
                    _openExistential(context, do: project)
                }
                return
            }
            if adapter.context == nil {
                let coordinator = content.makeCoordinator()
                let context: ContextLayout<_Content.Coordinator>.V1
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *),
                    let values = try? swift_getFieldValue("values", ContextLayout<Representable.Coordinator>.V4.RepresentableContextValues.self, bridgedContext)
                {
                    context = ContextLayout<_Content.Coordinator>.V1(
                        coordinator: coordinator,
                        transaction: values.transaction,
                        environment: values.environment,
                        preferenceBridge: values.preferenceBridge
                    )
                } else {
                    let bridgedContext = unsafeBitCast(
                        bridgedContext,
                        to: ContextLayout<Representable.Coordinator>.V1.self
                    )
                    context = ContextLayout<_Content.Coordinator>.V1(
                        coordinator: coordinator,
                        transaction: bridgedContext.transaction,
                        environment: bridgedContext.environment,
                        preferenceBridge: bridgedContext.preferenceBridge
                    )
                }
                adapter.context = unsafeBitCast(context, to: _Content.Context.self)
            }
            func project<T>(_ value: T) -> _Content.Context {
                var ctx = unsafeBitCast(value, to: ContextLayout<_Content.Coordinator>.V1.self)
                adapter.transformViewControllerEnvironment(&ctx.environment)
                return unsafeBitCast(ctx, to: _Content.Context.self)
            }
            let ctx = _openExistential(adapter.context!, do: project)
            if adapter.viewController == nil {
                #if os(iOS) || os(tvOS) || os(visionOS)
                adapter.viewController = content.makeUIViewController(context: ctx)
                #elseif os(macOS)
                adapter.viewController = content.makeNSViewController(context: ctx)
                #endif
            }
            let viewController = adapter.viewController as! _Content.PlatformViewControllerType
            #if os(iOS) || os(tvOS) || os(visionOS)
            content.updateUIViewController(viewController, context: ctx)
            #elseif os(macOS)
            content.updateNSViewController(viewController, context: ctx)
            #endif
        }
    }
}

#if os(iOS)

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ViewControllerAdapter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ViewControllerAdapterPreview {
                /// Renders into a `HostingController`
            }

            ViewControllerAdapterPreview {
                /// Renders `ViewControllerPreview.UIViewControllerType` directly
                ViewControllerPreview()
            }
        }
    }

    struct ViewControllerPreview: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            let uiViewController = UIViewController()
            uiViewController.view.backgroundColor = .red
            return uiViewController
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

        }
    }

    struct ViewControllerAdapterPreview<Content: View>: UIViewRepresentable {
        var content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIView(context: Context) -> UIView {
            context.coordinator.adapter = ViewControllerAdapter(
                content: content,
                context: context
            )
            if context.coordinator.adapter.viewController.view.backgroundColor == .systemBackground {
                context.coordinator.adapter.viewController.view.backgroundColor = .green
            }
            return context.coordinator.adapter.viewController.view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            context.coordinator.adapter.updateViewController(
                content: content,
                context: context
            )
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var adapter: ViewControllerAdapter<Content, ViewControllerAdapterPreview<Content>>!
        }
    }
}

#endif

#endif
