//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A ``BindingTransform`` that transforms the value with a `ParseableFormatStyle`
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct FormatTransform<
    F: ParseableFormatStyle
>: BindingTransform {

    public typealias Input = F.FormatInput
    public typealias Output = F.FormatOutput

    /// The format style used to format and parse the value.
    public var format: F

    /// Creates a transform that formats and parses values with the given format style.
    @inlinable
    public init(format: F) {
        self.format = format
    }

    public func get(_ value: Input) -> Output {
        return format.format(value)
    }

    public func set(_ newValue: Output) throws -> Input {
        return try format.parseStrategy.parse(newValue)
    }
}

/// A ``BindingTransform`` that transforms an optional value with a `ParseableFormatStyle`
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct OptionalFormatTransform<
    F: ParseableFormatStyle
>: BindingTransform where F.FormatOutput: Hashable {

    public typealias Input = F.FormatInput?
    public typealias Output = F.FormatOutput

    /// The format style used to format and parse the value.
    public var format: F
    /// The output used when the input value is `nil`.
    public var defaultValue: Output

    /// Creates a transform that formats and parses values with the given format style,
    /// using `defaultValue` when the input value is `nil`.
    @inlinable
    public init(format: F, defaultValue: Output) {
        self.format = format
        self.defaultValue = defaultValue
    }

    public func get(_ value: Input) -> Output {
        guard let value else { return defaultValue }
        return format.format(value)
    }

    public func set(_ newValue: Output) throws -> Input {
        return try format.parseStrategy.parse(newValue)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Binding {

    /// Projects the binding to the formatted output of a `ParseableFormatStyle`.
    ///
    /// When a new value fails to parse, the underlying value is left unchanged.
    @inlinable
    @MainActor @preconcurrency
    public func format<
        F: ParseableFormatStyle
    >(
        _ format: F
    ) -> Binding<F.FormatOutput> where Value == F.FormatInput, Value: Hashable {
        projecting(
            FormatTransform(
                format: format
            )
        )
    }

    /// Projects the optional binding to the formatted output of a `ParseableFormatStyle`,
    /// using `defaultValue` when the underlying value is `nil`.
    ///
    /// When a new value fails to parse, the underlying value is left unchanged.
    @inlinable
    @MainActor @preconcurrency
    public func format<
        V,
        F: ParseableFormatStyle
    >(
        _ format: F,
        defaultValue: F.FormatOutput
    ) -> Binding<F.FormatOutput> where F.FormatInput == V, F.FormatOutput: Hashable, Value == V?, Value: Hashable {
        projecting(
            OptionalFormatTransform(
                format: format,
                defaultValue: defaultValue
            )
        )
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FormatTransform_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {

        @State var int = 42
        @State var double = 0.99
        @State var date = Date.now

        var body: some View {
            VStack {
                Text($int.format(.number).wrappedValue)
                Text($double.format(.number).wrappedValue)
                Text($double.format(.percent).wrappedValue)
                Text($date.format(.dateTime).wrappedValue)
            }
        }
    }
}
