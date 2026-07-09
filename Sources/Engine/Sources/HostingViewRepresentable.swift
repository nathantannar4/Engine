//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

#if os(macOS)

public protocol HostingViewRepresentable: NSViewRepresentable where NSViewType == HostingView<Content> {

    associatedtype Content: View
    var content: Content { get }

    func makeHostingView(_ hostingView: NSViewType, context: Context)
    func updateHostingView(_ hostingView: NSViewType, context: Context)
}

extension HostingViewRepresentable {

    public func makeNSView(context: Context) -> HostingView<Content> {
        let uiView = HostingView(content: content)
        makeHostingView(uiView, context: context)
        return uiView
    }

    public func updateNSView(_ nsView: HostingView<Content>, context: Context) {
        nsView.content = content
        updateHostingView(nsView, context: context)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSViewType,
        context: Context
    ) -> CGSize? {
        return nsView.sizeThatFits(ProposedSize(proposal))
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        nsView: NSViewType
    ) {
        size = nsView.sizeThatFits(ProposedSize(proposedSize))
    }
}

#else

public protocol HostingViewRepresentable: UIViewRepresentable where UIViewType == HostingView<Content> {

    associatedtype Content: View
    var content: Content { get }

    func makeHostingView(_ hostingView: UIViewType, context: Context)
    func updateHostingView(_ hostingView: UIViewType, context: Context)
}

extension HostingViewRepresentable {

    public func makeUIView(context: Context) -> HostingView<Content> {
        let uiView = HostingView(content: content)
        uiView.invalidatesIntrinsicContentSizeOnIdealSizeChange = true
        makeHostingView(uiView, context: context)
        return uiView
    }

    public func updateUIView(_ uiView: HostingView<Content>, context: Context) {
        uiView.content = content
        updateHostingView(uiView, context: context)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIViewType,
        context: Context
    ) -> CGSize? {
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize))
    }
}

#endif

// MARK: - Previews

struct HostingViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewRepresentable {
                Text("Hello, World")
            }
            .border(Color.black)

            StateAdapter(initialValue: false) { $flag in
                PreviewRepresentable {
                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        PreviewContent(flag: flag)
                    }
                }
            }

            PreviewRepresentable {
                StateAdapter(initialValue: false) { $flag in
                    Button {
                        withAnimation {
                            flag.toggle()
                        }
                    } label: {
                        PreviewContent(flag: flag)
                    }
                }
            }

            StateAdapter(initialValue: false) { $flag in
                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    PreviewContent(flag: flag)
                }
            }
        }
    }

    struct PreviewContent: View {
        var flag: Bool

        var body: some View {
            Text("Label")
                .padding(flag ? 16 : 8)
                .border(Color.accentColor)
        }
    }

    struct PreviewRepresentable<
        Content: View
    >: HostingViewRepresentable {

        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeHostingView(
            _ hostingView: HostingView<Content>,
            context: Context
        ) {
            // Add gestures, interactions, etc
        }

        func updateHostingView(
            _ hostingView: HostingView<Content>,
            context: Context
        ) {

        }
    }
}

#endif
