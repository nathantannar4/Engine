//
// Copyright (c) Nathan Tannar
//
#if !os(watchOS)
import SwiftUI

/// A view that flashes a debug overlay to indicate when a view update occurred
///
/// > Note: DEBUG builds only
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@frozen
public struct ViewUpdateDebugView<Content: View>: View {

    var content: Content
    #if DEBUG
    @UpdatePhase var phase
    #endif

    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public var body: some View {
        content
            #if DEBUG
            .modifier(ViewUpdateOverlayModifier(phase: phase) {
                ContainerRelativeShape()
                    .fill(Color.accentColor.opacity(0.3))
                    .border(Color.accentColor, width: 1)
            })
            #endif
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
extension View {

    /// A view that flashes a debug overlay to indicate when a view update occurred
    ///
    /// > Note: DEBUG builds only
    public func withViewUpdateDebugView() -> some View {
        #if DEBUG
        ViewUpdateDebugView { self }
        #else
        self
        #endif
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@frozen
public struct ViewUpdateOverlayModifier<Overlay: View>: ViewModifier {

    var overlay: Overlay
    var phase: UpdatePhase.Value

    @State var lastPhase = UpdatePhase.Value()

    var didRender: Bool {
        phase != lastPhase
    }

    public init(
        phase: UpdatePhase.Value,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.phase = phase
        self.overlay = overlay()
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if didRender {
                        overlay
                            .id(phase)
                    }
                }
                .animation(.linear(duration: 0.35), value: didRender)
                .allowsHitTesting(false)
                .environment(\.accessibilityEnabled, false)
                .onAppear {
                    lastPhase = phase
                }
                .onChange(of: phase) { newValue in
                    withCATransaction {
                        lastPhase = newValue
                    }
                }
            )
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
struct ViewUpdateDebugView_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value = 0

        var body: some View {
            VStack {
                Button {
                    value += 1
                } label: {
                    Text("Increment")
                }

                Text(value.description)
                    .withViewUpdateDebugView()

                NoUpdateView()

                UpdateView(value: value)
            }
        }

        struct NoUpdateView: View {
            var body: some View {
                Text("Static, No Update")
                    .withViewUpdateDebugView()
            }
        }

        struct UpdateView: View {
            var value: Int
            var body: some View {
                Text("Receives Updates")
                    .onChange(of: value) { _ in
                        // Do nothing, but view needs to use value somehow
                    }
                    .withViewUpdateDebugView()
            }
        }
    }
}
#endif
