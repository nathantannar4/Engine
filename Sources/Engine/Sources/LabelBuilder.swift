//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A collection of views suitible for a label, ideal for when you want to limit
/// the label to primitive ``Text``/``Image``.
@frozen
public struct LabelElement {

    public var image: Image?
    public var title: Text?
    public var subtitle: Text?

    @inlinable
    public init(
        image: Image? = nil,
        title: Text? = nil,
        subtitle: Text? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
}

/// A custom parameter attribute that constructs a `LabelElement` from closures, which takes
/// the first `Image` as the icon and the first `Text` as the title. Optionally include a second
/// `Text` for the subtitle.
@frozen
@resultBuilder
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct LabelElementBuilder {

    @frozen
    public enum LabelElementComponent {
        case image(Image)
        case text(Text)
    }

    public static func buildBlock() -> [LabelElementComponent] { [] }

    public static func buildPartialBlock(
        first component: Void
    ) -> [LabelElementComponent] { [] }

    public static func buildPartialBlock(
        first component: Never
    ) -> [LabelElementComponent] { }

    public static func buildPartialBlock(
        first component: Text
    ) -> [LabelElementComponent] {
        [.text(component)]
    }

    public static func buildPartialBlock(
        first component: Image
    ) -> [LabelElementComponent] {
        [.image(component)]
    }

    public static func buildPartialBlock(
        component: [LabelElementComponent]
    ) -> [LabelElementComponent] {
        component
    }

    public static func buildPartialBlock(
        accumulated: [LabelElementComponent],
        next component: Text
    ) -> [LabelElementComponent] {
        accumulated + [.text(component)]
    }

    public static func buildPartialBlock(
        accumulated: [LabelElementComponent],
        next component: Image
    ) -> [LabelElementComponent] {
        accumulated + [.image(component)]
    }

    public static func buildPartialBlock(
        accumulated: [LabelElementComponent],
        next components: [LabelElementComponent]
    ) -> [LabelElementComponent] {
        accumulated + components
    }

    public static func buildOptional(
        _ component: [LabelElementComponent]?
    ) -> [LabelElementComponent] {
        component ?? []
    }

    public static func buildEither(
        first component: [LabelElementComponent]
    ) -> [LabelElementComponent] {
        component
    }

    public static func buildEither(
        second component: [LabelElementComponent]
    ) -> [LabelElementComponent] {
        component
    }

    public static func buildFinalResult(
        _ components: [LabelElementComponent]
    ) -> LabelElement {
        var image: Image?
        var title: Text?
        var subtitle: Text?
        for component in components {
            switch component {
            case .image(let component) where image == nil:
                image = component
            case .text(let component) where title == nil:
                title = component
            case .text(let component) where subtitle == nil:
                subtitle = component
            default:
                break
            }
        }
        return LabelElement(image: image, title: title, subtitle: subtitle)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Label {

    public init(
        @LabelElementBuilder label: () -> LabelElement
    ) where Title == TupleView<(Text?, Text?)>, Icon == Optional<Image> {
        let label = label()
        self.init {
            label.title
            label.subtitle
        } icon: {
            label.image
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct LabelBuilder_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            // Empty
            Label {

            }

            // Title
            Label {
                Text("Title")
            }

            // Image
            Label {
                Image(systemName: "apple.logo")
            }

            // Image + Title
            Label {
                Image(systemName: "apple.logo")
                Text("Title")
            }

            Label {
                Image(systemName: "apple.logo")
                if true {
                    Text("Title")
                }
            }

            // Image + Title + Subtitle
            Label {
                Image(systemName: "apple.logo")
                Text("Title")
                Text("Subtitle")
            }

            Label {
                Image(systemName: "apple.logo")
                Text("Title")
                Text("Subtitle")
                Text("Hidden")
            }

            Label {
                Image(systemName: "apple.logo")
                Text("Title")
                if true {
                    Text("Subtitle")
                }
            }

            Label {
                Image(systemName: "apple.logo")
                Text("Title")
                if true {
                    Text("On Subtitle")
                } else {
                    Text("Off Subtitle")
                }
            }
        }
    }
}
