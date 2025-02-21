//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Image {

    #if os(macOS)
    typealias PlatformRepresentable = NSImage
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    typealias PlatformRepresentable = UIImage
    #endif

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    public func toUIImage(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> UIImage? {
        toPlatformValue(in: environment)
    }
    #endif

    #if os(macOS)
    public func toNSImage(
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> NSImage? {
        toPlatformValue(in: environment)
    }
    #endif

    fileprivate func toPlatformValue(
        in environment: EnvironmentValues
    ) -> PlatformRepresentable? {
        ImageProvider(for: self)?.resolved(in: environment)
    }
}

private enum ImageProvider {

    case system(String)
    case named(String, Bundle?)
    case cg(CGImage, CGFloat, Image.Orientation)
    case image(Image.PlatformRepresentable)

    init?(for image: Image) {
        guard let base = Mirror(reflecting: image).descendant("provider", "base") else {
            return nil
        }

        let className = String(describing: type(of: base))
        let mirror = Mirror(reflecting: base)
        switch className {
        case "NamedImageProvider":
            guard let name = mirror.descendant("name") as? String else {
                return nil
            }
            if let location = mirror.descendant("location") {
                if String(describing: location) == "system" {
                    self = .system(name)
                } else {
                    let bundle = mirror.descendant("location", "bundle")
                    self = .named(name, bundle as? Bundle)
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
                let image = mirror.descendant("image"),
                let scale = mirror.descendant("scale") as? CGFloat,
                let orientation = mirror.descendant("orientation") as? Image.Orientation
            else {
                return nil
            }
            self = .cg(image as! CGImage, scale, orientation)

        default:
            return nil
        }
    }

    func resolved(in environment: EnvironmentValues) -> Image.PlatformRepresentable? {
        switch self {
        case .system(let name):
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let scale: UIImage.SymbolScale = {
                guard let scale = environment.imageScale else { return .unspecified }
                switch scale {
                case .small: return .small
                case .medium: return .medium
                case .large: return .large
                @unknown default:
                    return .unspecified
                }
            }()
            let config = environment.font?.toUIFont().map {
                UIImage.SymbolConfiguration(
                    font: $0,
                    scale: scale
                )
            } ?? UIImage.SymbolConfiguration(scale: scale)
            return UIImage(
                systemName: name,
                withConfiguration: config
            )
            #elseif os(macOS)
            if #available(macOS 11.0, *) {
                let scale: NSImage.SymbolScale? = {
                    switch environment.imageScale {
                    case .small: return .small
                    case .medium: return .medium
                    case .large: return .large
                    case .none: return nil
                    @unknown default:
                        return nil
                    }
                }()
                let config = environment.font?.toNSFont().map {
                    let attributes = $0.fontDescriptor.fontAttributes
                    let traits = attributes[.traits] as? [NSFontDescriptor.TraitKey: Any]
                    let weight = traits?[.weight] as? NSFont.Weight
                    if let scale {
                        return NSImage.SymbolConfiguration(
                            pointSize: $0.pointSize,
                            weight: weight ?? .regular,
                            scale: scale
                        )
                    } else {
                        return NSImage.SymbolConfiguration(
                            pointSize: $0.pointSize,
                            weight: weight ?? .regular
                        )
                    }
                } ?? NSImage.SymbolConfiguration(scale: scale ?? .medium)
                return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                    .withSymbolConfiguration(config)
            }
            return nil
            #endif
        case let .named(name, bundle):
            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
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
