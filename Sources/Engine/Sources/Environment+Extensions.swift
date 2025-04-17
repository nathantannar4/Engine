//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Accessors to internal keys ``Engine.EnvironmentKeyVisitor``
extension EnvironmentValues {

    /// The value for the ``.labelsHidden(_)`` modifier
    public var labelsHidden: Bool {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            enum Visibility {
                case automatic
                case visible
                case hidden
            }
            return self["LabelsVisibilityKey", default: Visibility.automatic] == .hidden
        }
        return self["LabelsHiddenKey", default: false]
    }

    /// The value for the ``.foregroundStyle(_)``/``.foregroundColor(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var foregroundStyle: AnyShapeStyle {
        self["ForegroundStyleKey", default: AnyShapeStyle(.foreground)]
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var foregroundColor: Color? {
        foregroundStyle.color
    }

    /// The value for the ``.tint(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var tint: AnyShapeStyle {
        self["TintKey", default: AnyShapeStyle(.tint)]
    }

    /// The value for the ``.accentColor(_)`` modifier
    public var accentColor: Color {
        self["AccentColorKey", default: Color.accentColor]
    }

    /// The value for the ``.underlineStyle(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var underlineStyle: Text.LineStyle? {
        self["UnderlineStyleKey"]
    }

    /// The value for the ``.strikethrough(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var strikethroughStyle: Text.LineStyle? {
        self["StrikethroughStyleKey"]
    }

    /// The value for the ``.kerning(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var kerning: CGFloat {
        self["DefaultKerningKey", default: 0]
    }

    /// The value for the ``.tracking(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var tracking: CGFloat {
        self["DefaultTrackingKey", default: 0]
    }

    /// The value for the ``.baselineOffset(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var baselineOffset: CGFloat {
        self["DefaultBaselineOffsetKey", default: 0]
    }

    /// The value for the ``.lineLimit(_, reservesSpace: Bool)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var lowerLineLimit: Int? {
        self["DefaultBaselineOffsetKey"]
    }

    /// The value for the ``.textScale(_)`` modifier
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var textScale: Text.Scale {
        self["TextScaleKey", default: Text.Scale.default]
    }

    /// The value for the ``.imageScale(_)`` modifier
    @available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
    public var imageScale: Image.Scale? {
        self["ImageScaleKey"]
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    /// The value for the ``.textInputAutocapitalization(_)`` modifier
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    public var textInputAutocapitalization: TextInputAutocapitalization {
        self["TextInputAutocapitalizationKey", default: TextInputAutocapitalization.never]
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// The value for the ``.textContentType(_)`` modifier
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public var textContentType: UITextContentType? {
        self["TextContentTypeKey"]
    }
    #endif
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct EnvironmentValues_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnvironmentValuePreview(keyPath: \.labelsHidden) {
                TextField("Label", text: .constant(""))
                    .fixedSize()
            } content: { isHidden in
                Text(isHidden.description)
            }
            .labelsHidden()

            EnvironmentValuePreview(keyPath: \.foregroundStyle) {
                Text("Hello, World")
            } content: { foregroundStyle in
                Circle()
                    .fill(foregroundStyle)
                    .fixedSize()
            }
            .foregroundStyle(.red)

            EnvironmentValuePreview(keyPath: \.tint) {
                Button("Action") { }
            } content: { foregroundStyle in
                Circle()
                    .fill(foregroundStyle)
                    .fixedSize()
            }
            .tint(.purple)

            EnvironmentValuePreview(keyPath: \.minimumScaleFactor) {
                Text("Hello, World")
                    .frame(width: 50)
            } content: { minimumScaleFactor in
                Text(minimumScaleFactor.description)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    struct EnvironmentValuePreview<Value, Source: View, Content: View>: View {

        var keyPath: KeyPath<EnvironmentValues, Value>
        var source: Source
        var content: (Value) -> Content

        init(
            keyPath: KeyPath<EnvironmentValues, Value>,
            @ViewBuilder source: () -> Source,
            @ViewBuilder content: @escaping (Value) -> Content
        ) {
            self.keyPath = keyPath
            self.source = source()
            self.content = content
        }

        var body: some View {
            HStack {
                source

                Divider()
                    .fixedSize()

                EnvironmentValueReader(keyPath) { value in
                    content(value)
                }
            }
        }
    }
}

