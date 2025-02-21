//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS, deprecated: 16.0, message: "Use the builtin SwiftUI.AnyShape")
@available(macOS, deprecated: 13.0, message: "Use the builtin SwiftUI.AnyShape")
@available(tvOS, deprecated: 16.0, message: "Use the builtin SwiftUI.AnyShape")
@available(watchOS, deprecated: 9.0, message: "Use the builtin SwiftUI.AnyShape")
@available(visionOS, deprecated: 1.1, message: "Use the builtin SwiftUI.AnyShape")
@frozen
public struct AnyShape: Shape {

    @usableFromInline
    var storage: AnyShapeStorageBase

    @available(iOS, deprecated: 16.0, renamed: "init(_:)")
    @available(macOS, deprecated: 13.0, renamed: "init(_:)")
    @available(tvOS, deprecated: 16.0, renamed: "init(_:)")
    @available(watchOS, deprecated: 9.0, renamed: "init(_:)")
    @available(visionOS, deprecated: 1.1, renamed: "init(_:)")
    @inlinable
    public init<S: Shape>(shape: S) {
        storage = AnyShapeStorage(shape)
    }

    public func path(in rect: CGRect) -> Path {
        storage.path(in: rect)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior {
        storage.layoutDirectionBehavior
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        storage.sizeThatFits(proposal)
    }

    public var animatableData: AnyAnimatableData {
        get { storage.animatableData }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.copy()
            }
            storage.animatableData = newValue
        }
    }
}

@usableFromInline
class AnyShapeStorageBase: @unchecked Sendable {
    func path(in rect: CGRect) -> Path {
        fatalError("base")
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    var layoutDirectionBehavior: LayoutDirectionBehavior {
        fatalError("base")
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        fatalError("base")
    }

    public var animatableData: AnyAnimatableData {
        get { fatalError("base") }
        set { fatalError("base") }
    }

    func copy() -> AnyShapeStorageBase {
        fatalError("base")
    }
}

@usableFromInline
final class AnyShapeStorage<S: Shape>: AnyShapeStorageBase, @unchecked Sendable {

    var shape: S

    @usableFromInline
    init(_ shape: S) {
        self.shape = shape
    }

    override func path(in rect: CGRect) -> Path {
        shape.path(in: rect)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    override var layoutDirectionBehavior: LayoutDirectionBehavior {
        shape.layoutDirectionBehavior
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        shape.sizeThatFits(proposal)
    }

    override var animatableData: AnyAnimatableData {
        get {
            AnyAnimatableData(shape.animatableData)
        }
        set {
            if let newValue = newValue.as(S.AnimatableData.self) {
                shape.animatableData = newValue
            }
        }
    }

    override func copy() -> AnyShapeStorageBase {
        AnyShapeStorage(shape)
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
struct AnyShape_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var flag = true

        var body: some View {
            VStack(alignment: .leading) {
                Text("Engine.AnyShape ")

                HStack {
                    let shape = flag ? AnyShape(shape: Circle()) : AnyShape(shape: Rectangle())
                    shape
                        .fill(Color.yellow)

                    Color.red
                        .clipShape(shape)
                }
                .frame(height: 60)

                HStack {
                    let shape = AnyShape(shape: RoundedRectangle(cornerRadius: flag ? 25.0 : 0))
                    shape
                        .fill(Color.yellow)

                    Color.red
                        .clipShape(shape)
                }
                .frame(height: 60)

                Text("SwiftUI.AnyShape")
                HStack {
                    let shape = flag ? SwiftUI.AnyShape(Circle()) : SwiftUI.AnyShape(Rectangle())
                    shape
                        .fill(Color.yellow)

                    Color.red
                        .clipShape(shape)
                }
                .frame(height: 60)

                HStack {
                    let shape = SwiftUI.AnyShape(RoundedRectangle(cornerRadius: flag ? 25.0 : 0))
                    shape
                        .fill(Color.yellow)

                    Color.red
                        .clipShape(shape)
                }
                .frame(height: 60)
            }
            .padding()
            .onTapGesture {
                withAnimation {
                    flag.toggle()
                }
            }
        }
    }
}
