//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A type-erased view modifier.
///
/// An `AnyViewModifier` allows changing the type of view modifier used in a given view
/// hierarchy. Whenever the type of view used with an `AnyViewModifier` changes, the old
/// hierarchy is destroyed and a new hierarchy is created for the new type.
@frozen
public struct AnyViewModifier: ViewModifier {

    @usableFromInline
    var storage: AnyViewModifierStorageBase

    /// Create an instance that type-erases `view`.
    public init<M: ViewModifier>(_ modifier: M) {
        storage = AnyViewModifierStorage(modifier)
    }

    public func body(content: Content) -> some View {
        storage.body(content: content)
    }

    public func concat<M: ViewModifier>(_ modifier: M) -> AnyViewModifier {
        storage.concat(modifier)
    }
}

extension View {

    @inlinable
    public func modifier<C: Collection, Modifier: ViewModifier>(
        _ collection: C,
        makeModifier: (C.Element) -> Modifier
    ) -> some View {
        let modifier = collection.reduce(
            into: AnyViewModifier(EmptyModifier())
        ) { modifier, value in
            modifier = modifier.concat(makeModifier(value))
        }
        return self.modifier(modifier)
    }
}

@usableFromInline
@MainActor @preconcurrency
class AnyViewModifierStorageBase {
    func body(content: AnyViewModifier.Content) -> AnyView { fatalError() }
    func concat<M: ViewModifier>(_ modifier: M) -> AnyViewModifier { fatalError() }
}

private class AnyViewModifierStorage<Modifier: ViewModifier>: AnyViewModifierStorageBase {
    let modifier: Modifier
    init(_ modifier: Modifier) { self.modifier = modifier }

    override func body(content: AnyViewModifier.Content) -> AnyView {
        AnyView(content.modifier(modifier))
    }

    override func concat<M: ViewModifier>(_ modifier: M) -> AnyViewModifier {
        AnyViewModifier(self.modifier.concat(modifier))
    }
}

// MARK: - Previews

struct AnyViewModifier_Previews: PreviewProvider {
    struct Modifier: ViewModifier {
        var color: Color
        func body(content: Content) -> some View {
            content
                .padding(8)
                .background(color)
        }
    }

    static var previews: some View {
        VStack {
            Text("Hello, World")
                .modifier(
                    AnyViewModifier(
                        Modifier(color: .red)
                    )
                )

            Text("Hello, World")
                .modifier(
                    AnyViewModifier(
                        Modifier(color: .red)
                    )
                    .concat(
                        Modifier(color: .blue)
                    )
                )

            let colors: [Color] = [.red, .blue, .yellow]
            Text("Hello, World")
                .modifier(colors) { color in
                    Modifier(color: color)
                }
        }
    }
}
