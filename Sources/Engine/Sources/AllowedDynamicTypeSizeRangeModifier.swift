//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EnvironmentValues {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public var allowedDynamicTypeSize: ClosedRange<DynamicTypeSize> {
        get { self[AllowedDynamicTypeSizeKey.self] }
        set { self[AllowedDynamicTypeSizeKey.self] = newValue }
    }
}

/// A modifier that sets the allowed `DynamicTypeSize` range and writes the value to the environment
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct AllowedDynamicTypeSizeRangeModifier<Range: RangeExpression>: ViewModifier where Range.Bound == DynamicTypeSize {

    var range: Range

    public init(range: Range) {
        self.range = range
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.allowedDynamicTypeSize, range.asClosedRange())
            .dynamicTypeSize(range)
    }
}

extension View {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func allowedDynamicTypeSize<R: RangeExpression>(
        _ range: R
    ) -> some View where R.Bound == DynamicTypeSize {
        modifier(AllowedDynamicTypeSizeRangeModifier(range: range))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct AllowedDynamicTypeSizeKey: EnvironmentKey {
    static let defaultValue: ClosedRange<DynamicTypeSize> = DynamicTypeSize.xSmall...DynamicTypeSize.accessibility5
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension RangeExpression where Bound == DynamicTypeSize {

    func asClosedRange() -> ClosedRange<DynamicTypeSize> {
        let all = DynamicTypeSize.allCases
        let lower = all.first(where: { contains($0) }) ?? .xSmall
        let upper = all.last(where: { contains($0) }) ?? .accessibility5
        return lower...upper
    }
}
