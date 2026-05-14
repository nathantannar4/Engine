//
// Copyright (c) Nathan Tannar
//

import SwiftUI
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

private enum ImageProvider {

    case system(String)
    case named(String, Bundle?)
    case cg(CGImage, CGFloat, Image.Orientation)
    case image(Image.PlatformRepresentable)

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
                return nil
            }
            if let location = try? swift_getFieldValue("location", Any.self, base) {
                if String(describing: location) == "system" {
                    self = .system(name)
                } else {
                    let bundle = try? swift_getFieldValue("location", Bundle.self, location)
                    self = .named(name, bundle)
                }
            } else {
                self = .named(name, nil)
            }

        case "\(Image.PlatformRepresentable.self)":
            guard let image = base as? Image.PlatformRepresentable else {
                return nil
            }
            self = .image(image)

        case "CGImageProvider":
            guard
                let image = try? swift_getFieldValue("name", String.self, base),
                let scale = try? swift_getFieldValue("scale", CGFloat.self, base),
                let orientation = try? swift_getFieldValue("orientation", Image.Orientation.self, base)
            else {
                return nil
            }
            self = .cg(image as! CGImage, scale, orientation)

        default:
            os_log(.debug, log: .default, "Failed to resolve Image provider %{public}@. Please file an issue.", className)
            return nil
        }
    }

    func resolved(
        in environment: @autoclosure () -> EnvironmentValues? = nil
    ) -> Image.PlatformRepresentable? {
        switch self {
        case .system(let name):
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let config = environment()?.symbolConfiguration()
            return UIImage(systemName: name, withConfiguration: config)
            #elseif os(macOS)
            if #available(macOS 11.0, *) {
                if let config = environment()?.symbolConfiguration() {
                    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                        .withSymbolConfiguration(config)
                }
                return NSImage(systemSymbolName: name, accessibilityDescription: nil)
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

extension EnvironmentValues {

    @available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
    func symbolConfiguration() -> Image.PlatformRepresentable.SymbolConfiguration? {
        let scale: Image.PlatformRepresentable.SymbolScale? = imageScale.flatMap { imageScale in
            switch imageScale {
            case .small: return .small
            case .medium: return .medium
            case .large: return .large
            @unknown default: return nil
            }
        }
        let font = font?.toPlatformValue(in: self)
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        if let font, let scale {
            return UIImage.SymbolConfiguration(font: font, scale: scale)
        } else if let font {
            return UIImage.SymbolConfiguration(font: font)
        } else if let scale {
            return UIImage.SymbolConfiguration(scale: scale)
        }
        return nil
        #elseif os(macOS)
        let attributes = font?.fontDescriptor.fontAttributes
        let traits = attributes?[.traits] as? [NSFontDescriptor.TraitKey: Any]
        let weight = traits?[.weight] as? NSFont.Weight
        let pointSize = font?.pointSize

        if let pointSize, let weight, let scale {
            return NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight, scale: scale)
        } else if let scale {
            return NSImage.SymbolConfiguration(scale: scale)
        }
        return nil
        #endif
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    func traitCollectionForImageResolution() -> UITraitCollection {
        let traits: [UITraitCollection?] = [
            UITraitCollection(
                displayScale: displayScale
            ),
            {
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
                return contrast.map {
                    UITraitCollection(accessibilityContrast: $0)
                }
            }(),
            {
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
                return userInterfaceStyle.map {
                    UITraitCollection(userInterfaceStyle: $0)
                }
            }()
        ]
        return UITraitCollection(traitsFrom: traits.compactMap({ $0 }))
    }
    #endif
}
