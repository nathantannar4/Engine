<img src="./Logo.png" width="128"> 

# Engine

A performance driven framework for developing SwiftUI frameworks and apps. `Engine` makes it easier to create idiomatic APIs and Views that feel natural in SwiftUI without sacrificing performance.

## Requirements

- Deployment target: iOS 13.0, macOS 10.15, tvOS 13.0, or watchOS 6.0
- Xcode 14.1+

## Installation

### Xcode Projects

Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/nathantannar4/Engine`.

### Swift Package Manager Projects

You can add `Engine` as a package dependency in your `Package.swift` file:

```swift
let package = Package(
    //...
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Engine"),
    ],
    targets: [
        .target(
            name: "YourPackageTarget",
            dependencies: [
                .product(name: "Engine", package: "Engine"),
            ],
            //...
        ),
        //...
    ],
    //...
)
```

## Introduction to Engine


For some sample code to get started with `Engine`, build and run the included "Example" project.

### Custom View Styles

A view style makes developing reusable components easier. This can be especially useful for framework developers who want a component to have a customizable appearance. Look no further than SwiftUI itself. With Engine, you can bring the same functionality to your app or framework by adopting the `ViewStyle` protocol. Unlike some other styling solutions you made have come across, `ViewStyle` works without relying on `AnyView` so it is very performant.

[Read More](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/ViewStyle.swift)

```
public protocol ViewStyle {
    associatedtype Configuration
    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
}

public protocol ViewStyledView: View {
    associatedtype Configuration
    var configuration: Configuration { get }

    associatedtype DefaultStyle: ViewStyle where DefaultStyle.Configuration == Configuration
    static var defaultStyle: DefaultStyle { get }
}
```

### Variadic Views

A variadic view allows many possibilities with SwiftUI to be unlocked, as it permits a transform of a single view into a collection of subviews. To learn more [MovingParts](https://movingparts.io/variadic-views-in-swiftui) has a great block post on the subject.

[Read More](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/VariadicView.swift)

```
@frozen
public struct VariadicViewAdapter<Source: View, Content: View>: View {

    @inlinable
    public init(
        @ViewBuilder content: @escaping (VariadicView<Source>) -> Content, 
        @ViewBuilder source: () -> Source
    )
}
```

### Availability

Supporting multiple release versions for SwiftUI can be tricky. If a modifier or view is available in a newer release, you have probably used `if #available(...)`. While this works, it is not performant since `@ViewBuilder` will turn this into an `AnyView`. Moreover, the code can become harder to read. For this reason, Engine has `VersionedView` and `VersionedViewModifier` for writing views with a `body` that can be different based on release availability.

[Read More](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/VersionedView.swift)

```
public protocol VersionedView: View where Body == Never {
    associatedtype V4Body: View = V3Body

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @ViewBuilder var v4Body: V4Body { get }

    associatedtype V3Body: View = V2Body

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder var v3Body: V3Body { get }

    associatedtype V2Body: View = V1Body

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @ViewBuilder var v2Body: V2Body { get }

    associatedtype V1Body: View = EmptyView

    @ViewBuilder var v1Body: V1Body { get }
}
```

### Static Conditionals

Should you ever have a modifier or view that is conditional upon a static flag, Engine provides `StaticConditionalContent` and `StaticConditionalModifier`. A great example is a view or modifier is different depending on the user interface idiom. When you use an `if/else` in a `@ViewBuilder`, the Swift compiler doesn't know that the condition is static. So SwiftUI will need to be ready for the condition to change, which can hinder performance needlessly if you know the condition is static. 

[Read More](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/StaticConditionalContent.swift)

```
public protocol StaticCondition {
    static var value: Bool { get }
}

@frozen
public struct StaticConditionalContent<
    Condition: StaticCondition,
    TrueContent: View,
    FalseContent: View
>: View {
    
    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewBuilder then: () -> TrueContent,
        @ViewBuilder else: () -> FalseContent
    )
}

@frozen
public struct StaticConditionalModifier<
    Condition: StaticCondition,
    TrueModifier: ViewModifier,
    FalseModifier: ViewModifier
>: ViewModifier {

    @inlinable
    public init(
        _ : Condition.Type = Condition.self,
        @ViewModifierBuilder then: () -> TrueModifier,
        @ViewModifierBuilder else: () -> FalseModifier
    )
}
```

## License

Distributed under the BSD 2-Clause License. See ``LICENSE.md`` for more information.
