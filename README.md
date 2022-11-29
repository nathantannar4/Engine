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

A view style makes developing reusable components easier. This can be especially useful for framework developers who want a component to have a customizable appearance. Look no further than SwiftUI itself. With `Engine`, you can bring the same functionality to your app or framework by adopting the `ViewStyle` protocol. Unlike some other styling solutions you made have come across, `ViewStyle` works without relying on `AnyView` so it is very performant.

[Open ViewStyle.swift](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/ViewStyle.swift)

#### Examples

You can use the `ViewStyle` APIs to make components that share common behavior and/or styling, such as font/colors, while allowing for complete customization of the appearance and layout. For example, this `StepperView` is a component that defaults to `Stepper` but allows for a different custom styling to be used. 

```
// 1. Define the style
protocol StepperViewStyle: ViewStyle where Configuration == StepperViewStyleConfiguration { }

// 2. Define the style's configuration
struct StepperViewStyleConfiguration {
    struct Label: ViewAlias { } // This lets the `StepperView` type erase the `Label` when used with a `StepperViewStyle`
    var label: Label { .init() }

    var onIncrement: () -> Void
    var onDecrement: () -> Void
}

// 3. Define the default style
struct DefaultStepperViewStyle: StepperViewStyle {
    func makeBody(configuration: StepperViewStyleConfiguration) -> some View {
        Stepper {
            configuration.label
        } onIncrement: {
            configuration.onIncrement()
        } onDecrement: {
            configuration.onDecrement()
        }
    }
}

// 4. Define your custom styles
struct InlineStepperViewStyle: StepperViewStyle {
    func makeBody(configuration: StepperViewStyleConfiguration) -> some View {
        HStack {
            Button {
                configuration.onDecrement()
            } label: {
                Image(systemName: "minus.circle.fill")
            }

            configuration.label

            Button {
                configuration.onIncrement()
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                configuration.onIncrement()
            case .decrement:
                configuration.onDecrement()
            default:
                break
            }
        }
    }
}

// 5. Add an extension to set the styles
extension View {
    func stepperViewStyle<Style: StepperViewStyle>(_ style: Style) -> some View {
        styledViewStyle(StepperViewBody.self, style: style)
    }
}

// 6. Define the component
struct StepperView<Label: View>: View {
    var label: Label
    var onIncrement: () -> Void
    var onDecrement: () -> Void

    init(
        @ViewBuilder label: () -> Label,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) {
        self.label = label()
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }

    var body: some View {
        StepperViewBody(
            configuration: .init(
                onIncrement: onIncrement,
                onDecrement: onDecrement
            )
        )
        .viewAlias(StepperViewStyleConfiguration.Label.self) {
            label
        }
    }
}

extension StepperView where Label == StepperViewStyleConfiguration.Label {
    init(_ configuration: StepperViewStyleConfiguration) {
        self.label = configuration.label
        self.onIncrement = configuration.onIncrement
        self.onDecrement = configuration.onDecrement
    }
}

// 7. Define the component as a `ViewStyledView`. The `body` is optional.
struct StepperViewBody: ViewStyledView {
    var configuration: StepperViewStyleConfiguration

    var body: some View {
        StepperView(configuration)
			// This styling will apply to every `StepperView` regardless of the style used
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary)
            )
    }

    static var defaultStyle: DefaultStepperViewStyle {
        DefaultStepperViewStyle()
    }
}
```

[Open Examples](https://github.com/nathantannar4/Engine/blob/main/Example/Example/ViewStyleExamples.swift)

### Variadic Views

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

A variadic view allows many possibilities with SwiftUI to be unlocked, as it permits a transform of a single view into a collection of subviews. To learn more [MovingParts](https://movingparts.io/variadic-views-in-swiftui) has a great block post on the subject.

[Open VariadicView.swift](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/VariadicView.swift)

#### Examples

You can use `VariadicViewAdapter` to write components like a custom picker view.

```
enum Fruit: Hashable, CaseIterable {
    case apple
    case orange
    case banana
}

struct FruitPicker: View {
    @State var selection: Fruit = .apple

    var body: some View {
        PickerView(selection: $selection) {
            ForEach(Fruit.allCases, id: \.self) { fruit in
                Text(fruit.rawValue)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PickerView<Selection: Hashable, Content: View>: View {
    @Binding var selection: Selection
    @ViewBuilder var content: Content

    var body: some View {
        VariadicViewAdapter { content in
            ForEachSubview(content) { index, subview in
                HStack {
                    // This works since the ForEach ID is the Fruit (ie Selection) type
                    let isSelected: Bool = selection == subview.id(as: Selection.self)
                    if isSelected {
                        Image(systemName: "checkmark")
                    }

                    Button {
                        selection = subview.id(as: Selection.self)!
                    } label: {
                        subview
                    }
                }
            }
        } source: {
            content
        }
    }
}
```

[Open Examples](https://github.com/nathantannar4/Engine/blob/main/Example/Example/VariadicViewExamples.swift)

### Availability

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

Supporting multiple release versions for SwiftUI can be tricky. If a modifier or view is available in a newer release, you have probably used `if #available(...)`. While this works, it is not performant since `@ViewBuilder` will turn this into an `AnyView`. Moreover, the code can become harder to read. For this reason, `Engine` has `VersionedView` and `VersionedViewModifier` for writing views with a `body` that can be different based on release availability.

[Open VersionedView.swift](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/VersionedView.swift)

#### Examples

You can use `VersionedViewModifier` to help adopt newer SwiftUI APIs with less friction. Such as adopting a new view type like `Grid`, while still supporting older iOS versions with a custom grid view; or using new view modifiers which due to the required `if #available(...)` checks can force you to refactor your code.

```
struct ContentView: VersionedView {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    var v4Body: some View {
        Grid {
            // ...
        }
    }

    var v1Body: some View {
        CustomGridView {
            // ...
        }
    }
}

struct UnderlineIfAvailableModifier: VersionedViewModifier {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func v4Body(content: Content) -> some View {
        content.underline()
    }
}

struct UnderlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(UnderlineIfAvailableModifier()) // #if #available(...) not required
    }
}

struct ContentView: View {
    var body: some View {
        Button {
            // ....
        } label: {
            Text("Underline if #available")
        }
        .buttonStyle(UnderlineButtonStyle())
    }
}
```

[Open More Examples](https://github.com/nathantannar4/Engine/blob/main/Example/Example/VersionedViewExamples.swift)

### Static Conditionals

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

Should you ever have a modifier or view that is conditional upon a static flag, `Engine` provides `StaticConditionalContent` and `StaticConditionalModifier`. A great example is a view or modifier is different depending on the user interface idiom. When you use an `if/else` in a `@ViewBuilder`, the Swift compiler doesn't know that the condition is static. So SwiftUI will need to be ready for the condition to change, which can hinder performance needlessly if you know the condition is static. 

[Open StaticConditionalContent.swift](https://github.com/nathantannar4/Engine/blob/main/Sources/Engine/Sources/StaticConditionalContent.swift)

#### Examples

You can use `StaticConditionalContent` to gate features or content to Debug or Testflight builds without impacting your production build performance.

```
struct IsDebug: StaticCondition {
    static var value: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

struct ProfileView: View {
    var body: some View {
        StaticConditionalContent(IsDebug.self) { // More performant than `if IsDebug.value ...`
            NewProfileView()
        } else: {
            LegacyProfileView()
        }
    }
}
```

[Open More Examples](https://github.com/nathantannar4/Engine/blob/main/Example/Example/StaticConditionalExamples.swift)

## License

Distributed under the BSD 2-Clause License. See ``LICENSE.md`` for more information.
