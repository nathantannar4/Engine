//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A static condition that is conditional on a view's inputs.
public protocol ViewInputsCondition {
    static func evaluate(_ inputs: ViewInputs) -> Bool
}

extension ViewInputsCondition where Self: ViewInputFlag {
    /// Evaluates to `true` when the input value is `true`
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        inputs[Self.Key.self]
    }
}

@frozen
public struct IsAxisDefined: ViewInputsCondition {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        inputs.options.contains(.isAxisDefined)
    }
}

@frozen
public struct IsAxisHorizontal: ViewInputsCondition {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        guard inputs.options.contains(.isAxisDefined) else { return false }
        return inputs.options.contains(.isAxisHorizontal)
    }
}

@frozen
public struct IsAxisVertical: ViewInputsCondition {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        guard inputs.options.contains(.isAxisDefined) else { return false }
        return !inputs.options.contains(.isAxisHorizontal)
    }
}

@frozen
public struct IsInLazyContainer: ViewInputsCondition, ViewInputFlag {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        if let isLazy = inputs[Self.self, default: nil] {
            return isLazy
        }
        return inputs["IsInLazyContainer", as: Bool.self] ?? false
    }
}

@frozen
public struct IsInScrollView: ViewInputsCondition, ViewInputFlag {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        if let isInScrollView = inputs[Self.self, default: nil] {
            return isInScrollView
        }
        return StyleContextCondition<ScrollViewStyleContext>.evaluate(inputs)
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct IsInHostingConfiguration: ViewInputsCondition, ViewInputFlag {
    public static func evaluate(_ inputs: ViewInputs) -> Bool {
        if let isInHostingConfiguration = inputs[Self.self, default: nil] {
            return isInHostingConfiguration
        }
        return inputs["IsInHostingConfiguration", as: Bool.self] ?? false
    }
}

extension ViewInputsCondition {

    @inlinable
    public static func evaluate(_ inputs: _ViewInputs) -> Bool {
        evaluate(ViewInputs(inputs: inputs))
    }

    @inlinable
    public static func evaluate(_ inputs: _ViewListInputs) -> Bool {
        evaluate(ViewInputs(inputs: inputs))
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @inlinable
    public static func evaluate(_ inputs: _ViewListCountInputs) -> Bool {
        evaluate(ViewInputs(inputs: inputs))
    }
}

// MARK: - Previews

struct ViewInputsCondition_Previews: PreviewProvider {

    struct DefinedAxisPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsAxisDefined.self) {
                Text("Axis Defined")
            } otherwise: {
                Text("Axis Undefined")
            }
        }
    }

    struct VerticalAxisPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsAxisVertical.self) {
                Text("Axis Vertical")
            } otherwise: {
                Text("Axis Non-Vertical")
            }
        }
    }

    struct HorizontalAxisPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsAxisHorizontal.self) {
                Text("Axis Horizontal")
            } otherwise: {
                Text("Axis Non-Horizontal")
            }
        }
    }

    struct IsInLazyContainerPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsInLazyContainer.self) {
                Text("Lazy Container")
            } otherwise: {
                Text("Non-Lazy Container")
            }
        }
    }

    @available(iOS 14.0, tvOS 14.0, *)
    struct IsInHostingConfigurationPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsInHostingConfiguration.self) {
                Text("HostingConfiguration Container")
            } otherwise: {
                Text("Non-HostingConfiguration Container")
            }
        }
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    struct HostingConfigurationWrapper<Content: View>: UIViewRepresentable {
        var content: Content

        func makeUIView(context: Context) -> UIView {
            UIHostingConfiguration {
                content
            }
            .margins(.all, 0)
            .makeContentView()
        }

        func updateUIView(_ uiView: UIView, context: Context) { }
    }
    #endif

    struct IsInScrollViewPreview: View {
        var body: some View {
            ViewInputConditionalContent(IsInScrollView.self) {
                Text("ScrollView Container")
            } otherwise: {
                Text("Non-ScrollView Container")
            }
        }
    }

    static var previews: some View {
        VStack {
            ZStack {
                DefinedAxisPreview()
            }

            UnaryViewAdaptor {
                DefinedAxisPreview()
            }

            #if os(iOS) || os(tvOS) || os(visionOS)
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                IsInHostingConfigurationPreview()

                HostingConfigurationWrapper(content: IsInHostingConfigurationPreview())
                    .fixedSize()
            }
            #endif

            Divider()

            VStack {
                VerticalAxisPreview()
                HorizontalAxisPreview()
                IsInLazyContainerPreview()
            }

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                LazyVStack {
                    VerticalAxisPreview()
                    HorizontalAxisPreview()
                    IsInLazyContainerPreview()
                }

                LazyVGrid(columns: [.init()]) {
                    VerticalAxisPreview()
                    HorizontalAxisPreview()
                    IsInLazyContainerPreview()
                }
            }

            Divider()

            HStack {
                VerticalAxisPreview()
                HorizontalAxisPreview()
            }

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                LazyHStack {
                    VerticalAxisPreview()
                    HorizontalAxisPreview()
                    IsInLazyContainerPreview()
                }
                .fixedSize()

                LazyHGrid(rows: [.init()]) {
                    VerticalAxisPreview()
                    HorizontalAxisPreview()
                    IsInLazyContainerPreview()
                }
                .fixedSize()
            }

            Divider()

            IsInScrollViewPreview()

            ScrollView {
                IsInScrollViewPreview()
            }
            .fixedSize()

            HStack {
                ScrollView(.horizontal) {
                    IsInScrollViewPreview()
                }
            }
        }
    }
}
