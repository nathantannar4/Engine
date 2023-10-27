# EngineCore

The visitor pattern enables casting from a generic type T to a  protocol with an associated type so that the concrete type can be utilized.

```swift
struct ViewAccessor: ViewVisitor {
    var input: Any

    var output: AnyView {
        func project<T>(_ input: T) -> AnyView {
            var visitor = Visitor(input: input)
            let conformance = ViewProtocolDescriptor.conformance(of: T.self)!
            conformance.visit(visitor: &visitor)
            return visitor.output
        }
        return _openExistential(input, do: project)
    }

    struct Visitor<T>: ViewVisitor {
        var input: T
        var output: AnyView!

        mutating func visit<Content: View>(type: Content.Type) {
            let view = unsafeBitCast(input, to: Content.self)
            output = AnyView(view)
        }
    }
}

let value: Any = Text("Hello, World!")
let accessor = ViewAccessor(input: value)
let view = accessor.output
print(view) // AnyView(Text("Hello, World!"))
```
