//
// Copyright (c) Nathan Tannar
//

import SwiftUI

#if !os(watchOS)

@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct AttributedText: View {

    @usableFromInline
    enum Storage: Equatable {
        case text(Text)
        case attributedString(NSAttributedString)
    }
    @usableFromInline
    var storage: Storage

    @inlinable
    public init(
        _ text: Text
    ) {
        self.storage = .text(text)
    }

    @inlinable
    public init(
        _ attributedString: NSAttributedString
    ) {
        self.storage = .attributedString(attributedString)
    }

    public var body: some View {
        AttributedTextBody(storage: storage)
            .equatable()
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
private struct AttributedTextBody: PlatformViewRepresentable, Equatable {

    nonisolated(unsafe) var storage: AttributedText.Storage

    #if os(macOS)
    typealias NSViewType = PlatformViewType
    func makeNSView(
        context: Context
    ) -> NSViewType {
        let nsView = NSViewType()
        return nsView
    }

    func updateNSView(
        _ nsView: NSViewType,
        context: Context
    ) {
        updateView(nsView, context: context)
    }

    @available(macOS 13.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSViewType,
        context: Context
    ) -> CGSize? {
        return nsView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        nsView: NSViewType
    ) {
        size = nsView.sizeThatFits(ProposedSize(proposedSize))
    }
    #else
    typealias UIViewType = PlatformViewType
    func makeUIView(
        context: Context
    ) -> UIViewType {
        let uiView = UIViewType()
        return uiView
    }

    func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        updateView(uiView, context: context)
    }

    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIViewType,
        context: Context
    ) -> CGSize? {
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize))
    }
    #endif

    func updateView(
        _ platformView: PlatformViewType,
        context: Context
    ) {
        let lineLimit = context.environment.lineLimit
        platformView.lineLimit = lineLimit
        platformView.minimumScaleFactor = context.environment.minimumScaleFactor
        platformView.lineBreakMode = context.environment.truncationMode.toNSLineBreakMode(lineLimit: lineLimit)
        switch storage {
        case .text(let text):
            platformView.setAttributedString(text.resolveAttributed(in: context.environment))
        case .attributedString(let attributedString):
            platformView.setAttributedString(attributedString)
        }
    }

    class PlatformViewType: PlatformView {

        var lineLimit: Int? {
            get { textContainer.maximumNumberOfLines }
            set {
                let maximumNumberOfLines = max(newValue ?? 0, 0)
                guard maximumNumberOfLines != textContainer.maximumNumberOfLines else { return }
                textContainer.maximumNumberOfLines = maximumNumberOfLines
                invalidateIntrinsicContentSize()
                #if os(macOS)
                needsDisplay = true
                #else
                setNeedsDisplay()
                #endif
            }
        }

        var minimumScaleFactor: CGFloat = 1 {
            didSet {
                guard oldValue != minimumScaleFactor else { return }
                invalidateIntrinsicContentSize()
                #if os(macOS)
                needsDisplay = true
                #else
                setNeedsDisplay()
                #endif
            }
        }

        var lineBreakMode: NSLineBreakMode {
            get { textContainer.lineBreakMode }
            set {
                guard newValue != lineBreakMode else { return }
                textContainer.lineBreakMode = newValue
                invalidateIntrinsicContentSize()
                #if os(macOS)
                needsDisplay = true
                #else
                setNeedsDisplay()
                #endif
            }
        }

        private let textStorage = NSTextStorage()
        private let layoutManager = NSLayoutManager()
        private let textContainer = NSTextContainer()

        #if os(macOS)
        override var isFlipped: Bool { true }
        #endif

        override init(frame: CGRect) {
            super.init(frame: frame)
            #if !os(macOS)
            backgroundColor = nil
            isOpaque = false
            #endif

            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = .byWordWrapping
            layoutManager.usesFontLeading = false
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setAttributedString(_ attributedString: NSAttributedString) {
            textStorage.setAttributedString(attributedString)
            invalidateIntrinsicContentSize()
            #if os(macOS)
            needsDisplay = true
            #else
            setNeedsDisplay()
            #endif
        }

        func sizeThatFits(_ proposal: ProposedSize) -> CGSize {
            let fittingSize = proposal
                .replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
            textContainer.size = fittingSize
            layoutManager.ensureLayout(for: textContainer)
            var sizeThatFits = layoutManager.usedRect(for: textContainer).size
            #if os(macOS)
            let scale = window?.backingScaleFactor ?? 1
            sizeThatFits.height = ceil(sizeThatFits.height.rounded(scale: scale))
            sizeThatFits.width = sizeThatFits.width.rounded(scale: scale)
            #else
            let scale = traitCollection.displayScale
            sizeThatFits.height = sizeThatFits.height.rounded(scale: scale)
            sizeThatFits.width = sizeThatFits.width.rounded(scale: scale)
            #endif
            return sizeThatFits
        }

        override func draw(_ rect: CGRect) {
            textContainer.size = rect.size
            layoutManager.ensureLayout(for: textContainer)
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
            layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        }

        #if os(macOS)
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            NotificationCenter.default.removeObserver(
                self,
                name: NSWindow.didChangeBackingPropertiesNotification,
                object: nil
            )
            if let window {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(didChangeBackingPropertiesNotification),
                    name: NSWindow.didChangeBackingPropertiesNotification,
                    object: window
                )
            }
        }

        @objc
        private func didChangeBackingPropertiesNotification() {
            needsDisplay = true
            invalidateIntrinsicContentSize()
        }
        #endif
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
struct AttributedText_Previews: PreviewProvider {
    struct TextPreview: View {
        var text: Text

        @Environment(\.self) var environment

        var body: some View {
            VStack(spacing: 48) {
                text
                    .withDebugOverlay(label: "Text", color: .red)

                AttributedText(text)
                    .withDebugOverlay(label: "AttributedText", color: .blue)

                #if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
                Label(attributedText: text.resolveAttributed(in: environment))
                    .withDebugOverlay(label: "Label", color: .green)
                #endif

                text
                    .hidden()
                    .overlay {
                        GeometryReader { proxy in
                            let size = text.sizeThatFits(proxy.size, environment: environment)
                            Rectangle()
                                .hidden()
                                .frame(width: size.width, height: size.height)
                                .overlay {
                                    ZStack {
                                        AttributedText(text)
                                        text
                                    }
                                }
                                .withDebugOverlay(label: "sizeThatFits", color: .yellow)
                        }
                    }
            }
            .frame(width: 400)
            .fixedSize(horizontal: false, vertical: true)
            .padding(32)
        }

        #if os(iOS) || os(tvOS) || os(visionOS)
        struct Label: UIViewRepresentable {
            var attributedText: NSAttributedString

            func makeUIView(context: Context) -> UILabel {
                let uiView = UILabel()
                return uiView
            }

            func updateUIView(_ uiView: UILabel, context: Context) {
                uiView.numberOfLines = max(context.environment.lineLimit ?? 0, 0)
                uiView.lineBreakMode = context.environment.truncationMode.toNSLineBreakMode(lineLimit: context.environment.lineLimit)
                let attributedText = NSMutableAttributedString(attributedString: attributedText)
                attributedText.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedText.length)) { value, range, _ in
                    attributedText.removeAttribute(.paragraphStyle, range: range)
                }
                uiView.attributedText = attributedText
            }

            @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
            func sizeThatFits(
                _ proposal: ProposedViewSize,
                uiView: UIViewType,
                context: Context
            ) -> CGSize? {
                let fittingSize = proposal.replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
                var sizeThatFits = uiView.sizeThatFits(fittingSize)
                sizeThatFits.width = min(sizeThatFits.width, fittingSize.width)
                return sizeThatFits
            }

            func _overrideSizeThatFits(
                _ size: inout CGSize,
                in proposedSize: _ProposedSize,
                uiView: UIViewType
            ) {
                let fittingSize = ProposedSize(proposedSize).replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
                var sizeThatFits = uiView.sizeThatFits(fittingSize)
                sizeThatFits.width = min(sizeThatFits.width, fittingSize.width)
                size = sizeThatFits
            }
        }
        #elseif os(macOS)
        struct Label: NSViewRepresentable {
            var attributedText: NSAttributedString

            func makeNSView(context: Context) -> NSTextField {
                let nsView = NSTextField()
                nsView.isEditable = false
                nsView.isSelectable = false
                nsView.isBezeled = false
                nsView.drawsBackground = false
                nsView.focusRingType = .none
                nsView.lineBreakMode = .byWordWrapping
                return nsView
            }

            func updateNSView(_ nsView: NSTextField, context: Context) {
                nsView.maximumNumberOfLines = max(context.environment.lineLimit ?? 0, 0)
                nsView.attributedStringValue = attributedText
            }

            @available(macOS 13.0, *)
            func sizeThatFits(
                _ proposal: ProposedViewSize,
                nsView: NSViewType,
                context: Context
            ) -> CGSize? {
                let fittingSize = proposal.replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
                var sizeThatFits = nsView.sizeThatFits(fittingSize)
                sizeThatFits.width = min(sizeThatFits.width, fittingSize.width)
                sizeThatFits.height = ceil(sizeThatFits.height)
                return sizeThatFits
            }

            func _overrideSizeThatFits(
                _ size: inout CGSize,
                in proposedSize: _ProposedSize,
                nsView: NSViewType
            ) {
                let fittingSize = ProposedSize(proposedSize).replacingUnspecifiedDimensions(
                    by: CGSize(
                        width: CGFloat.infinity,
                        height: CGFloat.infinity
                    )
                )
                var sizeThatFits = nsView.sizeThatFits(fittingSize)
                sizeThatFits.width = min(sizeThatFits.width, fittingSize.width)
                sizeThatFits.height = ceil(sizeThatFits.height)
                size = sizeThatFits
            }
        }
        #endif
    }

    static var previews: some View {
        VStack {
            TextPreview(
                text: Text("Hello, World")
            )
        }

        VStack {
            TextPreview(
                text: Text("\(Text(Image(systemName: "globe.americas.fill")).font(.system(size: 50)).foregroundColor(.blue).baselineOffset(2)) Hello, \(Text("World").font(.headline.bold()))").font(.caption)
            )
        }

        VStack {
            TextPreview(
                text: Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis.")
            )
        }

        VStack {
            TextPreview(
                text: Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis.")
            )
            .lineLimit(1)
        }

        VStack {
            TextPreview(
                text: Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis.")
            )
            .lineLimit(2)
            .truncationMode(.middle)
        }
    }
}

#endif
