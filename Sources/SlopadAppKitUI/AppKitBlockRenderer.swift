import AppKit
import CoreGraphics
import SlopadAppKitTextKit
import SlopadEngine

// MARK: - AppKitBlockRenderer

@MainActor
public protocol AppKitBlockRenderer {
    func drawBlock(_ context: AppKitBlockRenderContext)
}

// MARK: - AppKitBlockRenderContext

public struct AppKitBlockRenderContext {
    public let renderedBlock: EditorRenderedBlock
    public let snapshot: EditorSessionSnapshot
    public let style: TextKitEditorStyle
    public let textLayouter: TextKitBlockTextLayouter
    public let textRenderer: TextKitBlockRenderer
    public let dirtyRect: NSRect
    public let graphicsContext: CGContext
    public let isActive: Bool
    public let isSelected: Bool

    public init(
        renderedBlock: EditorRenderedBlock,
        snapshot: EditorSessionSnapshot,
        style: TextKitEditorStyle,
        textLayouter: TextKitBlockTextLayouter,
        textRenderer: TextKitBlockRenderer,
        dirtyRect: NSRect,
        graphicsContext: CGContext,
        isActive: Bool,
        isSelected: Bool
    ) {
        self.renderedBlock = renderedBlock
        self.snapshot = snapshot
        self.style = style
        self.textLayouter = textLayouter
        self.textRenderer = textRenderer
        self.dirtyRect = dirtyRect
        self.graphicsContext = graphicsContext
        self.isActive = isActive
        self.isSelected = isSelected
    }
}

// MARK: - AppKitDefaultBlockRenderer

public struct AppKitDefaultBlockRenderer: AppKitBlockRenderer {
    // MARK: - Private Types

    private enum UX {
        static let activeBackgroundAlpha: CGFloat = 0.07
        static let selectedBackgroundAlpha: CGFloat = 0.16
        static let selectedBorderAlpha: CGFloat = 0.65
        static let selectedBorderInset: CGFloat = 1
        static let selectedBorderWidth: CGFloat = 1.5
        static let gutterSeparatorAlpha: CGFloat = 0.25
        static let gutterSeparatorWidth: CGFloat = 1
        static let gutterIconSize: CGFloat = 16
        static let gutterIconTopPadding: CGFloat = 9
        static let gutterFallbackInset: CGFloat = 4
        static let gutterSymbolFraction: CGFloat = 0.82
        static let gutterTextFontSize: CGFloat = 11
        static let activeSelectionAlpha: CGFloat = 0.35
        static let caretMinimumWidth: CGFloat = 1
        static let caretMinimumHeight: CGFloat = 14
    }

    // MARK: - Init

    public init() {}

    // MARK: - Public

    public func drawBlock(_ context: AppKitBlockRenderContext) {
        let rendered = context.renderedBlock
        let frame = CGRect(editorRect: rendered.frame)

        drawBlockBackground(frame, context: context)
        drawGutter(for: rendered, frame: frame, context: context)
        context.textRenderer.draw(rendered.textRender, context: context.graphicsContext)

        if context.isActive, let activeTextInput = context.snapshot.activeTextInput {
            drawActiveTextInputDecorations(activeTextInput, context: context)
        }
    }

    // MARK: - Block Drawing

    private func drawBlockBackground(_ frame: CGRect, context: AppKitBlockRenderContext) {
        let blockBackground: NSColor
        if context.isActive {
            blockBackground = NSColor.controlAccentColor.withAlphaComponent(UX.activeBackgroundAlpha)
        } else if context.isSelected {
            blockBackground = NSColor.selectedContentBackgroundColor
                .withAlphaComponent(UX.selectedBackgroundAlpha)
        } else {
            blockBackground = .clear
        }
        blockBackground.setFill()
        frame.fill()

        if context.isSelected {
            NSColor.selectedContentBackgroundColor.withAlphaComponent(UX.selectedBorderAlpha)
                .setStroke()
            let path = NSBezierPath(
                rect: frame.insetBy(
                    dx: UX.selectedBorderInset,
                    dy: UX.selectedBorderInset
                )
            )
            path.lineWidth = UX.selectedBorderWidth
            path.stroke()
        }
    }

    private func drawGutter(
        for rendered: EditorRenderedBlock,
        frame: CGRect,
        context: AppKitBlockRenderContext
    ) {
        let gutterRect = CGRect(
            x: 0,
            y: frame.minY,
            width: context.style.gutterWidth,
            height: frame.height
        )
        NSColor.separatorColor.withAlphaComponent(UX.gutterSeparatorAlpha).setFill()
        CGRect(
            x: gutterRect.maxX - UX.gutterSeparatorWidth,
            y: gutterRect.minY,
            width: UX.gutterSeparatorWidth,
            height: gutterRect.height
        ).fill()
        drawGutterMarker(for: rendered, in: gutterRect)
    }

    // MARK: - Active Input Drawing

    private func drawActiveTextInputDecorations(
        _ descriptor: EditorSessionActiveTextInputDescriptor,
        context: AppKitBlockRenderContext
    ) {
        NSColor.selectedTextBackgroundColor.withAlphaComponent(UX.activeSelectionAlpha).setFill()
        for rect in selectionRects(for: descriptor, context: context) where rect.width > 0 {
            rect.fill()
        }

        guard let caretRect = caretRect(for: descriptor, context: context) else { return }
        NSColor.controlAccentColor.setFill()
        CGRect(
            x: caretRect.minX,
            y: caretRect.minY,
            width: max(UX.caretMinimumWidth, caretRect.width),
            height: max(UX.caretMinimumHeight, caretRect.height)
        ).fill()
    }

    private func caretRect(
        for descriptor: EditorSessionActiveTextInputDescriptor,
        context: AppKitBlockRenderContext
    ) -> CGRect? {
        let request = descriptor.renderDescriptor.measureRequest
        let position = TextPosition(blockID: request.blockID, offset: descriptor.focusOffset)
        guard
            let localRect = context.textLayouter.caretRect(
                for: position,
                in: descriptor.renderDescriptor
            )
        else { return nil }
        return documentRect(localRect, in: descriptor.renderDescriptor, context: context)
    }

    private func selectionRects(
        for descriptor: EditorSessionActiveTextInputDescriptor,
        context: AppKitBlockRenderContext
    ) -> [CGRect] {
        context.textLayouter.selectionRects(
            for: descriptor.selectedRange,
            in: descriptor.renderDescriptor
        ).map {
            documentRect($0, in: descriptor.renderDescriptor, context: context)
        }
    }

    private func documentRect(
        _ localRect: EditorRect,
        in descriptor: EditorTextRenderDescriptor,
        context: AppKitBlockRenderContext
    ) -> CGRect {
        let localFrame = context.textLayouter.textFrame(for: descriptor, measuredHeight: nil)
        return CGRect(
            x: CGFloat(localRect.x + descriptor.frame.x - localFrame.x),
            y: CGFloat(localRect.y + descriptor.frame.y - localFrame.y),
            width: CGFloat(localRect.width),
            height: CGFloat(localRect.height)
        )
    }

    // MARK: - Gutter Drawing

    private func drawGutterMarker(for rendered: EditorRenderedBlock, in rect: CGRect) {
        if case .orderedListItem(let number) = rendered.markerKind {
            drawGutterText("\(number).", in: rect)
            return
        }

        let symbolName: String
        switch rendered.markerKind {
        case .unorderedListItem:
            symbolName = "list.bullet"
        case .todo(let checked):
            symbolName = checked ? "checkmark.square" : "square"
        case .none:
            symbolName = gutterSymbolName(for: rendered.kind)
        case .orderedListItem:
            symbolName = "list.number"
        }

        drawGutterSymbol(symbolName, in: rect)
    }

    private func gutterSymbolName(for kind: BlockKind) -> String {
        switch kind {
        case .heading:
            return "h.square"
        case .unorderedListItem:
            return "list.bullet"
        case .orderedListItem:
            return "list.number"
        case .todo(let checked):
            return checked ? "checkmark.square" : "square"
        case .quote:
            return "quote.opening"
        case .codeBlock:
            return "curlybraces"
        case .divider:
            return "minus"
        case .paragraph:
            return "line.3.horizontal"
        }
    }

    private func drawGutterSymbol(_ symbolName: String, in rect: CGRect) {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        let imageRect = CGRect(
            x: rect.midX - UX.gutterIconSize / 2,
            y: rect.minY + UX.gutterIconTopPadding,
            width: UX.gutterIconSize,
            height: UX.gutterIconSize
        )
        NSColor.secondaryLabelColor.set()
        if let image {
            image.draw(
                in: imageRect,
                from: .zero,
                operation: .sourceOver,
                fraction: UX.gutterSymbolFraction
            )
        } else {
            NSBezierPath(
                ovalIn: imageRect.insetBy(
                    dx: UX.gutterFallbackInset,
                    dy: UX.gutterFallbackInset
                )
            ).fill()
        }
    }

    private func drawGutterText(_ text: String, in rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: UX.gutterTextFontSize,
                weight: .medium
            ),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle,
        ]
        text.draw(
            in: CGRect(
                x: rect.minX,
                y: rect.minY + UX.gutterIconTopPadding,
                width: rect.width,
                height: UX.gutterIconSize
            ),
            withAttributes: attributes
        )
    }
}
