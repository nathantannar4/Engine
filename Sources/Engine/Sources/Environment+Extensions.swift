//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// Accessors to internal keys ``Engine.EnvironmentKeyVisitor``
extension EnvironmentValues {

    #if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 17.0, tvOS 17.0, visionOS 1.0, *)
    public var hostingController: UIViewController? {
        self["WithCurrentHostingControllerKey"]
    }
    #endif

    /// The value for the ``.labelsHidden(_)`` modifier
    public var labelsHidden: Bool {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return labelsVisibility == .hidden
        }
        return self["LabelsHiddenKey", default: false]
    }

    /// The value for the ``.foregroundStyle(_)``/``.foregroundColor(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var foregroundStyle: AnyShapeStyle {
        self["ForegroundStyleKey", default: AnyShapeStyle(.foreground)]
    }

    public var foregroundColor: Color? {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
            let foregroundStyle = self["ForegroundStyleKey", as: AnyShapeStyle.self]
        {
            return foregroundStyle.color(in: self)
        }
        return self["ForegroundColorKey"]
    }

    /// The value for the ``.tint(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var tintStyle: AnyShapeStyle {
        self["TintKey", default: AnyShapeStyle(.tint)]
    }

    /// The color for the ``.tint(_)`` modifier
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var tintColor: Color? {
        tintStyle.color(in: self)
    }

    /// The value for the ``.accentColor(_)`` modifier
    public var accentColor: Color {
        self["AccentColorKey", default: Color.accentColor]
    }

    /// The value for the ``.underline(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var underlineStyle: Text.LineStyle? {
        self["UnderlineStyleKey"]
    }

    /// The value for the ``.strikethrough(_)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
    public var lineLimitMininum: Int? {
        self["LowerLineLimitKey"]
    }

    /// The value for the ``.lineLimit(_, reservesSpace: Bool)`` modifier
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var lineLimitRange: ClosedRange<Int>? {
        let min = lineLimitMininum ?? 0
        let max = lineLimit ?? Int.max
        return min...max
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
    public var textInputAutocapitalization: TextInputAutocapitalization {
        self["TextInputAutocapitalizationKey", default: TextInputAutocapitalization.never]
    }
    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// The value for the ``.textContentType(_)`` modifier
    public var textContentType: UITextContentType? {
        let rawValue = self["TextContentTypeKey", as: UITextContentType.RawValue.self]
        return rawValue.map({ UITextContentType(rawValue: $0) })
    }

    /// The value for the ``.keyboardType(_)`` modifier
    public var keyboardType: UIKeyboardType {
        self["KeyboardTypeKey", default: UIKeyboardType.default]
    }
    #endif

    /// The value for the display corner radius
    public var displayCornerRadius: CGFloat? {
        self["DisplayCornerRadiusKey"]
    }

    /// The value for the color scheme of the system
    public var colorSchemeContrast: ColorSchemeContrast {
        get { _colorSchemeContrast }
        set { _colorSchemeContrast = newValue }
    }

    /// The value for the color scheme of the system
    public var systemColorScheme: ColorScheme {
        self["SystemColorSchemeKey", default: .light]
    }

    /// The value for the ``.preferredColorScheme(_)`` modifier
    public var preferredColorScheme: ColorScheme? {
        self["ExplicitPreferredColorSchemeKey"]
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension TextInputAutocapitalization {
    enum Behaviour {
        case never
        case words
        case sentences
        case characters
    }
}

extension UITextAutocapitalizationType {

    @available(iOS 15.0, tvOS 15.0, *)
    public init?(_ textInputAutocapitalization: TextInputAutocapitalization) {
        guard
            let behaviour = try? swift_getFieldValue("behavior", TextInputAutocapitalization.Behaviour?.self, textInputAutocapitalization)
        else {
            return nil
        }
        switch behaviour {
        case .never:
            self = .none
        case .words:
            self = .words
        case .sentences:
            self = .sentences
        case .characters:
            self = .allCharacters
        }
    }
}
#endif

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
            .foregroundStyle(.green)

            EnvironmentValuePreview(keyPath: \.foregroundStyle) {
                Text("Hello, World")
            } content: { foregroundStyle in
                Circle()
                    .fill(foregroundStyle)
                    .fixedSize()
            }
            .foregroundStyle(.green)

            EnvironmentValuePreview(keyPath: \.foregroundColor) {
                Text("Hello, World")
            } content: { foregroundColor in
                Circle()
                    .fill(foregroundColor ?? .black)
                    .fixedSize()
            }
            .foregroundStyle(.green)

            EnvironmentValuePreview(keyPath: \.tintStyle) {
                Button("Action") { }
            } content: { tintStyle in
                Circle()
                    .fill(tintStyle)
                    .fixedSize()
            }
            .tint(.green)

            EnvironmentValuePreview(keyPath: \.tintColor) {
                Button("Action") { }
            } content: { tintColor in
                Circle()
                    .fill(tintColor ?? .red)
                    .fixedSize()
            }
            .tint(.green)

            EnvironmentValuePreview(keyPath: \.accentColor) {
                Button("Action") { }
            } content: { accentColor in
                Circle()
                    .fill(accentColor)
                    .fixedSize()
            }
            .accentColor(.green)

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                EnvironmentValuePreview(keyPath: \.underlineStyle) {
                    Text("Underline")
                } content: { underlineStyle in
                    Text(underlineStyle.debugDescription)
                }
                .underline()

                EnvironmentValuePreview(keyPath: \.strikethroughStyle) {
                    Text("Strikethrough")
                } content: { strikethroughStyle in
                    Text(strikethroughStyle.debugDescription)
                }
                .strikethrough()

                EnvironmentValuePreview(keyPath: \.kerning) {
                    Text("Kerning")
                } content: { kerning in
                    Text(kerning, format: .number)
                }
                .kerning(10)

                EnvironmentValuePreview(keyPath: \.tracking) {
                    Text("Tracking")
                } content: { tracking in
                    Text(tracking, format: .number)
                }
                .tracking(10)

                EnvironmentValuePreview(keyPath: \.baselineOffset) {
                    Text("Baseline Offset")
                } content: { baselineOffset in
                    Text(baselineOffset, format: .number)
                }
                .baselineOffset(10)

                HStack {
                    Text("Line Limit")

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitMininum) { lineLimitMininum in
                        Text(lineLimitMininum ?? -1, format: .number)
                    }
                    .lineLimit(2...3)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(2...3)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(2...)

                    Divider()
                        .fixedSize()

                    EnvironmentValueReader(\.lineLimitRange) { lineLimitRange in
                        Text(lineLimitRange?.description ?? "nil")
                    }
                    .lineLimit(...3)
                }
            }

            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                EnvironmentValuePreview(keyPath: \.textScale) {
                    Text("Hello, World")
                } content: { textScale in
                    Text(verbatim: "\(textScale)")
                }
                .textScale(.secondary)
            }

            /// The value for the ``.imageScale(_)`` modifier
            if #available(iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *) {
                EnvironmentValuePreview(keyPath: \.imageScale) {
                    Image(systemName: "apple.logo")
                } content: { imageScale in
                    Text(verbatim: "\(imageScale.debugDescription)")
                }
                .imageScale(.large)
            }

            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            /// The value for the ``.textInputAutocapitalization(_)`` modifier
            if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                EnvironmentValuePreview(keyPath: \.textInputAutocapitalization) {
                    TextField("Label", text: .constant(""))
                        .fixedSize()
                } content: { textInputAutocapitalization in
                    Text(verbatim: "\(textInputAutocapitalization)")
                }
                .textInputAutocapitalization(.characters)
            }
            #endif

            #if os(iOS) || os(tvOS) || os(visionOS)
            EnvironmentValuePreview(keyPath: \.keyboardType) {
                TextField("Label", text: .constant(""))
                    .fixedSize()

            } content: { keyboardType in
                Text(verbatim: "\(keyboardType)")
            }
            .keyboardType(.numberPad)
            #endif

            #if os(iOS) || os(tvOS) || os(visionOS)
            EnvironmentValuePreview(keyPath: \.textContentType) {
                TextField("Label", text: .constant(""))
                    .fixedSize()
            } content: { textContentType in
                Text(textContentType?.rawValue)
            }
            .textContentType(.name)
            #endif

            EnvironmentValuePreview(keyPath: \.displayCornerRadius) {
                EmptyView()
            } content: { displayCornerRadius in
                Text(displayCornerRadius ?? -1, format: .number)
            }

            EnvironmentValuePreview(keyPath: \.systemColorScheme) {
                EmptyView()
            } content: { systemColorScheme in
                Text(verbatim: "\(systemColorScheme)")
            }
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

