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

    public var format: F

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

/// A ``BindingTransform`` that transforms the value with a `ParseableFormatStyle`
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct OptionalFormatTransform<
    F: ParseableFormatStyle
>: BindingTransform {

    public typealias Input = F.FormatInput?
    public typealias Output = F.FormatOutput

    public var format: F
    public var defaultValue: Output

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

    @inlinable
    @MainActor @preconcurrency
    public func format<
        F: ParseableFormatStyle
    >(
        _ format: F
    ) -> Binding<F.FormatOutput> where Value == F.FormatInput {
        projecting(
            FormatTransform(
                format: format
            )
        )
    }

    @inlinable
    @MainActor @preconcurrency
    public func format<
        V,
        F: ParseableFormatStyle
    >(
        _ format: F,
        defaultValue: F.FormatOutput
    ) -> Binding<F.FormatOutput> where F.FormatInput == V, Value == V? {
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
