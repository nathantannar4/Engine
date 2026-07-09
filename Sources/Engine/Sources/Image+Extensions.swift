//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore
import os.log

extension Image {

    #if os(macOS)
    typealias PlatformRepresentable = NSImage
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIImage
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    public func toUIImage(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> UIImage? {
        toPlatformValue(in: environment())
    }
    #endif

    #if os(macOS)
    public func toNSImage(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> NSImage? {
        toPlatformValue(in: environment())
    }
    #endif

    func toPlatformValue(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> PlatformRepresentable? {
        ImageProvider(for: self)?.resolved(in: environment())
    }
}

private struct ImageProvider {

    enum Storage {
        case system(String, Float?)
        case named(String, Bundle?)
        case cg(CGImage, CGFloat, Image.Orientation)
        case image(Image.PlatformRepresentable)
    }
    var storage: Storage
    var capInsets: EdgeInsets?
    var resizingMode: Image.ResizingMode?
    var renderingMode: Image.TemplateRenderingMode?
    var symbolConfiguration = SymbolConfiguration()

    init?(for image: Image) {
        guard
            let provider = try? swift_getFieldValue("provider", Any.self, image),
            let base = try? swift_getFieldValue("base", Any.self, provider)
        else {
            return nil
        }

        let className = String(describing: type(of: base))
        switch className {
        case "NamedImageProvider":
            guard let name = try? swift_getFieldValue("name", String.self, base) else {
                fallthrough
            }
            if let location = try? swift_getFieldValue("location", Any.self, base) {
                if String(describing: location) == "system" {
                    let variableValue = try? swift_getFieldValue("value", Float?.self, base)
                    self.storage = .system(name, variableValue)
                } else {
                    let bundle = try? swift_getFieldValue("location", Bundle.self, location)
                    self.storage = .named(name, bundle)
                }
            } else {
                self.storage = .named(name, nil)
            }

        case "\(Image.PlatformRepresentable.self)":
            guard let image = base as? Image.PlatformRepresentable else {
                fallthrough
            }
            self.storage = .image(image)

        case "CGImageProvider":
            guard
                let image = try? swift_getFieldValue("name", String.self, base),
                let scale = try? swift_getFieldValue("scale", CGFloat.self, base),
                let orientation = try? swift_getFieldValue("orientation", Image.Orientation.self, base)
            else {
                fallthrough
            }
            self.storage = .cg(image as! CGImage, scale, orientation)

        case "ResizableProvider":
            guard
                let image = try? swift_getFieldValue("base", Image.self, base),
                let provider = ImageProvider(for: image)
            else {
                fallthrough
            }
            self = provider
            if let capInsets = try? swift_getFieldValue("capInsets", EdgeInsets.self, base) {
                self.capInsets = capInsets
            }
            if let resizingMode = try? swift_getFieldValue("resizingMode", Image.ResizingMode.self, base) {
                self.resizingMode = resizingMode
            }

        case "RenderingModeProvider":
            guard
                let image = try? swift_getFieldValue("base", Image.self, base),
                let provider = ImageProvider(for: image)
            else {
                fallthrough
            }
            self = provider
            if let renderingMode = try? swift_getFieldValue("renderingMode", Image.TemplateRenderingMode.self, base) {
                self.renderingMode = renderingMode
            }

        case "SymbolRenderingOptionsProvider":
            guard
                let image = try? swift_getFieldValue("base", Image.self, base),
                let provider = ImageProvider(for: image)
            else {
                fallthrough
            }
            self = provider
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), let options = try? swift_getFieldValue("options", Any.self, base) {
                if let symbolRenderingMode = try? swift_getFieldValue("renderingMode", SymbolRenderingModeStorage.self, options) {
                    self.symbolConfiguration.symbolRenderingMode = symbolRenderingMode
                }
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    if let symbolColorRenderingMode = try? swift_getFieldValue("colorMode", SymbolColorRenderingModeStorage.self, options) {
                        self.symbolConfiguration.symbolColorRenderingMode = symbolColorRenderingMode
                    }
                    if let symbolVariableValueMode = try? swift_getFieldValue("variableValueMode", SymbolVariableValueModeStorage.self, options) {
                        self.symbolConfiguration.symbolVariableValueMode = symbolVariableValueMode
                    }
                }
                #endif
            }

        case "AntialiasedProvider", "DynamicRangeProvider", "InterpolationProvider":
            guard
                let image = try? swift_getFieldValue("base", Image.self, base),
                let provider = ImageProvider(for: image)
            else {
                fallthrough
            }
            self = provider

        default:
            if let image = try? swift_getFieldValue("base", Image.self, base), let provider = ImageProvider(for: image) {
                os_log(.debug, log: .default, "Failed to fully resolve Image provider %{public}@. Please file an issue.", className)
                self = provider
            } else {
                os_log(.debug, log: .default, "Failed to resolve Image provider %{public}@. Please file an issue.", className)
                return nil
            }
        }
    }

    func resolved(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> Image.PlatformRepresentable? {
        guard var image = storage.resolved(symbolConfiguration: symbolConfiguration, in: environment()) else { return nil }
        if let renderingMode {
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            image = image.withRenderingMode(renderingMode == .template ? .alwaysTemplate : .alwaysOriginal)
            #else
            image.isTemplate = renderingMode == .template
            #endif
        }
        if let capInsets, let resizingMode {
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let capInsets = capInsets.toPlatformValue(layoutDirection: environment()?.layoutDirection ?? .leftToRight)
            image = image.resizableImage(withCapInsets: capInsets, resizingMode: resizingMode == .tile ? .tile : .stretch)
            #else
            image.resizingMode = resizingMode == .tile ? .tile : .stretch
            #endif
        }
        return image
    }
}

extension ImageProvider.Storage {

    func resolved(
        symbolConfiguration: SymbolConfiguration,
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> Image.PlatformRepresentable? {
        switch self {
        case .system(let name, let variableValue):
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let image: UIImage? = {
                let configuration = symbolConfiguration.resolve(in: environment())
                if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *), let variableValue {
                    return UIImage(systemName: name, variableValue: Double(variableValue), configuration: configuration)
                }
                return UIImage(systemName: name, withConfiguration: configuration)
            }()
            return image?.withRenderingMode(.alwaysTemplate)
            #elseif os(macOS)
            if #available(macOS 11.0, *) {
                let image: NSImage? = {
                    let configuration = symbolConfiguration.resolve(in: environment())
                    if #available(macOS 13.0, *), let variableValue {
                        return NSImage(systemSymbolName: name, variableValue: Double(variableValue), accessibilityDescription: nil)?
                            .withSymbolConfiguration(configuration)
                    }
                    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                        .withSymbolConfiguration(configuration)
                }()
                image?.isTemplate = true
                return image
            }
            return nil
            #endif

        case let .named(name, bundle):
            #if os(iOS) || os(tvOS) || os(visionOS)
            let traitCollection = environment()?.traitCollectionForImageResolution()
            return UIImage(named: name, in: bundle, compatibleWith: traitCollection)
            #elseif os(watchOS)
            return UIImage(named: name, in: bundle, with: nil)
            #elseif os(macOS)
            if #available(macOS 14.0, *), let bundle {
                return NSImage(resource: ImageResource(name: name, bundle: bundle))
            }
            return NSImage(named: name)
            #endif

        case let .image(image):
            return image

        case let .cg(image, scale, orientation):
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let orientation: UIImage.Orientation = {
                switch orientation {
                case .down: return .down
                case .downMirrored: return .downMirrored
                case .left: return .left
                case .leftMirrored: return .leftMirrored
                case .right: return .right
                case .rightMirrored: return .rightMirrored
                case .up: return .up
                case .upMirrored: return .upMirrored
                }
            }()
            return UIImage(cgImage: image, scale: scale, orientation: orientation)
            #elseif os(macOS)
            return NSImage(cgImage: image, size: .zero)
            #endif
        }
    }
}

extension SymbolConfiguration {

    @available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
    func resolve(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> Image.PlatformRepresentable.SymbolConfiguration {
        let environment = environment()
        let scale: Image.PlatformRepresentable.SymbolScale? = environment?.imageScale.flatMap { imageScale in
            switch imageScale {
            case .small: return .small
            case .medium: return .medium
            case .large: return .large
            @unknown default: return nil
            }
        }
        let font = environment?.font?.toPlatformValue(in: environment)
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        var configuration: UIImage.SymbolConfiguration = {
            if let font, let scale {
                return UIImage.SymbolConfiguration(font: font, scale: scale)
            } else if let font {
                return UIImage.SymbolConfiguration(font: font)
            } else if let scale {
                return UIImage.SymbolConfiguration(scale: scale)
            }
            return UIImage.SymbolConfiguration.unspecified
        }()
        if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, *), let locale = environment?.locale {
            configuration = configuration
                .applying(UIImage.SymbolConfiguration(locale: locale))
        }
        #if !os(watchOS)
        if let environment {
            let traitCollection = environment.traitCollectionForImageResolution()
            if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
                configuration = configuration
                    .applying(UIImage.SymbolConfiguration(traitCollection: traitCollection))
            } else {
                configuration = configuration.withTraitCollection(traitCollection)
            }
        }
        #endif
        #elseif os(macOS)
        let attributes = font?.fontDescriptor.fontAttributes
        let traits = attributes?[.traits] as? [NSFontDescriptor.TraitKey: Any]
        let weight = traits?[.weight] as? NSFont.Weight
        let pointSize = font?.pointSize

        var configuration: NSImage.SymbolConfiguration = {
            if let pointSize, let weight, let scale {
                return NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight, scale: scale)
            } else if let scale {
                return NSImage.SymbolConfiguration(scale: scale)
            }
            return NSImage.SymbolConfiguration()
        }()
        #endif
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            if let symbolRenderingMode = symbolRenderingMode ?? environment?.symbolRenderingMode?.storage {
                switch symbolRenderingMode {
                case .monochrome:
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        configuration = configuration.applying(Image.PlatformRepresentable.SymbolConfiguration.preferringMonochrome())
                    }
                    if let color = environment?.foregroundColor?.toPlatformValue(in: environment) {
                        configuration = configuration
                            .applying(Image.PlatformRepresentable.SymbolConfiguration(hierarchicalColor: color))

                    }
                case .multicolor:
                    configuration = configuration.applying(Image.PlatformRepresentable.SymbolConfiguration.preferringMulticolor())
                case .hierarchical:
                    if let color = environment?.foregroundColor?.toPlatformValue(in: environment) {
                        configuration = configuration
                            .applying(Image.PlatformRepresentable.SymbolConfiguration(hierarchicalColor: color))

                    }
                    #if os(macOS)
                    if #available(macOS 13.0, *) {
                        configuration = configuration
                            .applying(NSImage.SymbolConfiguration.preferringHierarchical())
                    }
                    #endif
                case .palette:
                    if let environment, let foregroundStyle = environment.foregroundStyle.resolve(in: environment) {
                        let colors = [
                            foregroundStyle.kind.color(in: environment, level: 0),
                            foregroundStyle.kind.color(in: environment, level: 1),
                            foregroundStyle.kind.color(in: environment, level: 2),
                        ].compactMap { $0?.toPlatformValue(in: environment) }
                        configuration = configuration
                            .applying(Image.PlatformRepresentable.SymbolConfiguration(paletteColors: colors))

                    }
                }
            }
            #if canImport(FoundationModels) // Xcode 26
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                if let symbolVariableValueMode = symbolVariableValueMode ?? environment?.symbolVariableValueMode?.storage {
                    configuration = configuration
                        .applying(Image.PlatformRepresentable.SymbolConfiguration(variableValueMode: symbolVariableValueMode.toPlatformValue()))
                }

                if let symbolColorRenderingMode = symbolColorRenderingMode ?? environment?.symbolColorRenderingMode?.storage {
                    configuration = configuration
                        .applying(Image.PlatformRepresentable.SymbolConfiguration(colorRenderingMode: symbolColorRenderingMode.toPlatformValue()))
                }
            }
            #endif
        }

        return configuration
    }
}

extension EnvironmentValues {

    #if os(iOS) || os(tvOS) || os(visionOS)
    func traitCollectionForImageResolution() -> UITraitCollection {
        let contrast: UIAccessibilityContrast? = {
            if #available(iOS 14.0, tvOS 14.0, *) {
                return UIAccessibilityContrast(colorSchemeContrast)
            }
            switch colorSchemeContrast {
            case .standard: return .normal
            case .increased: return .high
            @unknown default: return nil
            }
        }()
        let userInterfaceStyle: UIUserInterfaceStyle? = {
            if #available(iOS 14.0, tvOS 14.0, *) {
                return UIUserInterfaceStyle(colorScheme)
            }
            switch colorScheme {
            case .light: return .light
            case .dark: return .dark
            @unknown default: return nil
            }
        }()
        if #available(iOS 17.0, tvOS 17.0, *) {
            return UITraitCollection().modifyingTraits { mutableTraits in
                mutableTraits.displayScale = displayScale
                if let contrast {
                    mutableTraits.accessibilityContrast = contrast
                }
                if let userInterfaceStyle {
                    mutableTraits.userInterfaceStyle = userInterfaceStyle
                }
            }
        } else {
            var traits: [UITraitCollection] = [
                UITraitCollection(
                    displayScale: displayScale
                )
            ]
            if let contrast {
                traits.append(UITraitCollection(accessibilityContrast: contrast))
            }
            if let userInterfaceStyle {
                traits.append(UITraitCollection(userInterfaceStyle: userInterfaceStyle))
            }
            return UITraitCollection(traitsFrom: traits)
        }
    }
    #endif
}

struct SymbolConfiguration {
    var symbolRenderingMode: SymbolRenderingModeStorage?
    #if canImport(FoundationModels) // Xcode 26
    var symbolColorRenderingMode: SymbolColorRenderingModeStorage?
    var symbolVariableValueMode: SymbolVariableValueModeStorage?
    #endif
}

enum SymbolRenderingModeStorage {
    case monochrome
    case multicolor
    case hierarchical
    case palette
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SymbolRenderingMode {

    var storage: SymbolRenderingModeStorage? {
        try? swift_getFieldValue("storage", SymbolRenderingModeStorage.self, self)
    }
}

#if canImport(FoundationModels) // Xcode 26
enum SymbolColorRenderingModeStorage {
    case flat
    case gradient

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func toPlatformValue() -> Image.PlatformRepresentable.SymbolColorRenderingMode {
        switch self {
        case .flat:
            return .flat
        case .gradient:
            return .gradient
        }
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension SymbolColorRenderingMode {

    var storage: SymbolColorRenderingModeStorage? {
        try? swift_getFieldValue("storage", SymbolColorRenderingModeStorage.self, self)
    }
}

enum SymbolVariableValueModeStorage {
    case color
    case draw

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func toPlatformValue() -> Image.PlatformRepresentable.SymbolVariableValueMode {
        switch self {
        case .color:
            return .color
        case .draw:
            return .draw
        }
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension SymbolVariableValueMode {

    var storage: SymbolVariableValueModeStorage? {
        try? swift_getFieldValue("storage", SymbolVariableValueModeStorage.self, self)
    }
}
#endif

// MARK: - Previews

@available(macOS 11.0, *)
struct Image_Previews: PreviewProvider {
    struct ImagePreview: View {
        var image: Image

        var body: some View {
            HStack {
                image

                ImageView(image: image)
            }
        }

        #if os(iOS) || os(tvOS) || os(visionOS)
        struct ImageView: UIViewRepresentable {
            var image: Image

            func makeUIView(context: Context) -> UIImageView {
                let uiView = UIImageView()
                uiView.setContentHuggingPriority(.required, for: .vertical)
                uiView.setContentHuggingPriority(.required, for: .horizontal)
                return uiView
            }

            func updateUIView(_ uiView: UIImageView, context: Context) {
                if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                    uiView.tintColor = context.environment.foregroundColor?.toUIColor(in: context.environment)
                }
                uiView.image = image.toUIImage(in: context.environment)
            }
        }
        #elseif os(macOS)
        struct ImageView: NSViewRepresentable {
            var image: Image

            func makeNSView(context: Context) -> NSImageView {
                let nsView = NSImageView()
                nsView.setContentHuggingPriority(.required, for: .vertical)
                nsView.setContentHuggingPriority(.required, for: .horizontal)
                return nsView
            }

            func updateNSView(_ nsView: NSImageView, context: Context) {
                if #available(macOS 12.0, *) {
                    nsView.contentTintColor = context.environment.foregroundColor?.toNSColor(in: context.environment)
                }
                nsView.image = image.toNSImage(in: context.environment)
            }
        }
        #else
        struct ImageView: View {
            var image: Image

            @Environment(\.self) var environment

            var body: some View {
                Image(uiImage: image.toPlatformValue(in: environment) ?? UIImage())
            }
        }
        #endif
    }

    static var previews: some View {
        ImagePreview(
            image: Image(systemName: "globe.americas.fill")
        )

        VStack {
            ImagePreview(
                image: Image(systemName: "globe.americas.fill").renderingMode(.original)
            )
            .foregroundColor(.blue)

            ImagePreview(
                image: Image(systemName: "globe.americas.fill").renderingMode(.template)
            )
            .foregroundColor(.blue)
        }

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            VStack {
                ImagePreview(
                    image: Image(systemName: "calendar.badge")
                )

                ImagePreview(
                    image: Image(systemName: "calendar.badge").symbolRenderingMode(.hierarchical)
                )

                ImagePreview(
                    image: Image(systemName: "calendar.badge").symbolRenderingMode(.multicolor)
                )

                ImagePreview(
                    image: Image(systemName: "calendar.badge").symbolRenderingMode(.monochrome)
                )
                .foregroundColor(.yellow)

                ImagePreview(
                    image: Image(systemName: "calendar.badge").symbolRenderingMode(.palette)
                )
                .foregroundStyle(.red, .yellow)

                ImagePreview(
                    image: Image(systemName: "wifi").symbolRenderingMode(.palette)
                )

                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    ImagePreview(
                        image: Image(systemName: "wifi", variableValue: 0.5)
                    )
                }

                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    ImagePreview(
                        image: Image(systemName: "wifi").symbolVariableValueMode(.color)
                    )

                    ImagePreview(
                        image: Image(systemName: "wifi").symbolColorRenderingMode(.gradient)
                    )
                }
                #endif
            }
            .foregroundColor(.blue)
        }

        VStack {
            ImagePreview(
                image: Image(systemName: "globe.americas.fill").resizable()
            )

            ImagePreview(
                image: Image(systemName: "globe.americas.fill").resizable(capInsets: .init(top: 1, leading: 1, bottom: 1, trailing: 1), resizingMode: .stretch)
            )
        }
    }
}
