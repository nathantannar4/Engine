//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

#if !os(watchOS)

/// An adapter that converts a generic ``View`` into a view controller
@MainActor @preconcurrency
open class ViewControllerAdapter<
    Content: View,
    Representable: PlatformViewRepresentable
> {

    public var viewController: PlatformViewController!

    var context: Any! // Context<Coordinator>
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
        hostingController.update(content: content, transaction: context.transaction)
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

    private enum RepresentableContextValues {
        enum EnvironmentStorage {
            case eager(EnvironmentValues)
            case lazy(() -> EnvironmentValues)
        }

        struct Platform {
            var rawValue: UInt8
        }

        struct V8 {
            var preferenceBridge: AnyObject?
            var transaction: Transaction
            var environmentStorage: EnvironmentStorage
            var platform: Platform

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

        struct V4 {
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
    }

    private enum Context<Coordinator> {

        struct V8 {
            var values: RepresentableContextValues.V8
            var coordinator: Coordinator
        }
        case v8(V8)

        struct V4 {
            var values: RepresentableContextValues.V4
            var coordinator: Coordinator
        }
        case v4(V4)

        struct V1 {
            var coordinator: Coordinator
            var transaction: Transaction
            var environment: EnvironmentValues
            var preferenceBridge: AnyObject?
        }
        case v1(V1)

        var environment: EnvironmentValues {
            get {
                switch self {
                case .v8(let v8):
                    return v8.values.environment
                case .v4(let v4):
                    return v4.values.environment
                case .v1(let v1):
                    return v1.environment
                }
            }
            set {
                switch self {
                case .v8(var v8):
                    v8.values.environment = newValue
                    self = .v8(v8)
                case .v4(var v4):
                    v4.values.environment = newValue
                    self = .v4(v4)
                case .v1(var v1):
                    v1.environment = newValue
                    self = .v1(v1)
                }
            }
        }

        var coordinator: Coordinator {
            switch self {
            case .v8(let v8):
                return v8.coordinator
            case .v4(let v4):
                return v4.coordinator
            case .v1(let v1):
                return v1.coordinator
            }
        }

        func asPlatformViewControllerRepresentableContext<T>(to _: T.Type) -> T {
            let context: V1
            switch self {
            case .v8(let v8):
                context = .init(
                    coordinator: v8.coordinator,
                    transaction: v8.values.transaction,
                    environment: v8.values.environment,
                    preferenceBridge: v8.values.preferenceBridge
                )
            case .v4(let v4):
                context = .init(
                    coordinator: v4.coordinator,
                    transaction: v4.values.transaction,
                    environment: v4.values.environment,
                    preferenceBridge: v4.values.preferenceBridge
                )
            case .v1(let v1):
                context = v1
            }
            return unsafeBitCast(context, to: T.self)
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
                        let ctx = unsafeBitCast(value, to: Context<_Content.Coordinator>.self)
                        #if os(iOS) || os(tvOS) || os(visionOS)
                        _Content.dismantleUIViewController(viewController, coordinator: ctx.coordinator)
                        #elseif os(macOS)
                        _Content.dismantleNSViewController(viewController, coordinator: ctx.coordinator)
                        #endif
                    }
                    _openExistential(context, do: project)
                }
                return
            }
            if adapter.context == nil {
                let coordinator = content.makeCoordinator()
                let context: Context<_Content.Coordinator>
                if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *),
                    let values = try? swift_getFieldValue("values", RepresentableContextValues.V8.self, bridgedContext)
                {
                    context = .v8(
                        Context<_Content.Coordinator>.V8(
                            values: values,
                            coordinator: coordinator
                        )
                    )
                } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *),
                    let values = try? swift_getFieldValue("values", RepresentableContextValues.V4.self, bridgedContext)
                {
                    context = .v4(
                        Context<_Content.Coordinator>.V4(
                            values: values,
                            coordinator: coordinator
                        )
                    )
                } else {
                    let bridgedContext = unsafeBitCast(bridgedContext, to: Context<Representable.Coordinator>.V1.self)
                    context = .v1(
                        Context<_Content.Coordinator>.V1(
                            coordinator: coordinator,
                            transaction: bridgedContext.transaction,
                            environment: bridgedContext.environment,
                            preferenceBridge: bridgedContext.preferenceBridge
                        )
                    )
                }
                adapter.context = context
            }
            func project<T>(_ value: T) -> _Content.Context {
                var ctx = unsafeBitCast(value, to: Context<_Content.Coordinator>.self)
                adapter.transformViewControllerEnvironment(&ctx.environment)
                return ctx.asPlatformViewControllerRepresentableContext(to: _Content.Context.self)
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
                Text("Hello, World")
            }

            ViewControllerAdapterPreview {
                /// Renders `ViewControllerPreview.UIViewControllerType` directly
                ViewControllerPreview()
            }
        }
    }

    struct ViewControllerPreview: UIViewControllerRepresentable {
        func makeUIViewController(
            context: Context
        ) -> UIViewController {
            let uiViewController = UIViewController()
            return uiViewController
        }

        func updateUIViewController(
            _ uiViewController: UIViewController,
            context: Context
        ) {

        }
    }

    struct ViewControllerAdapterPreview<Content: View>: UIViewRepresentable {
        var content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIView(
            context: Context
        ) -> UIView {
            context.coordinator.adapter = Adapter(
                content: content,
                context: context
            )
            return context.coordinator.adapter.viewController.view
        }

        func updateUIView(
            _ uiView: UIView,
            context: Context
        ) {
            context.coordinator.adapter.updateViewController(
                content: content,
                context: context
            )
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var adapter: Adapter!
        }

        class Adapter: ViewControllerAdapter<Content, ViewControllerAdapterPreview<Content>> {

            override func makeHostingController(
                content: Content,
                context: ViewControllerAdapterPreview<Content>.Context
            ) -> PlatformViewController {
                let vc = HostingController(content: content)
                vc.view.backgroundColor = .systemGreen
                return vc
            }

            override func updateViewController(
                context: ViewControllerAdapter_Previews.ViewControllerAdapterPreview<Content>.Context
            ) {
                viewController.view.backgroundColor = .systemRed
            }
        }
    }
}

#endif

#endif
