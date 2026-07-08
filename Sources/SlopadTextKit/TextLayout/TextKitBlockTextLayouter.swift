import AppKit
import CoreGraphics
import Foundation
import SlopadEngine

// MARK: - TextKitBlockTextLayouter

public struct TextKitBlockTextLayouter: BlockTextLayoutProtocol, Sendable {
    public init(style: TextKitEditorStyle = TextKitEditorStyle()) {
        self.init(style: style, layoutContext: TextKitLayoutContext())
    }

    public func measure(_ request: BlockMeasureRequest) -> BlockMeasurement {
        let baseFont = TextKitAttributedStringBuilder.baseFont(for: request.kind, style: style)
        let metrics = TextKitBlockChromeMetrics.metrics(for: request.kind)
        let measuredTextHeight = layoutContext.measure(
            request,
            style: style,
            minimumHeight: CGFloat(baseFont.ascender - baseFont.descender)
        )

        return BlockMeasurement(
            height: Double(ceil(measuredTextHeight)) + metrics.verticalPadding,
            firstBaseline: metrics.topPadding + Double(baseFont.ascender)
        )
    }

    public func attributedString(for request: BlockMeasureRequest) -> NSAttributedString {
        TextKitAttributedStringBuilder.attributedString(for: request, style: style)
    }

    public func textFrame(for request: BlockMeasureRequest, measuredHeight: Double? = nil)
        -> EditorRect
    {
        let origin = style.textOrigin(depth: request.depth, kind: request.kind)
        let height = measuredHeight.map { max(1, $0 - origin.y) } ?? CGFloat.greatestFiniteMagnitude
        return EditorRect(
            x: Double(origin.x),
            y: Double(origin.y),
            width: style.textWidth(
                availableWidth: request.availableWidth,
                depth: request.depth
            ),
            height: Double(height)
        )
    }

    public func textFrame(
        for descriptor: EditorTextRenderDescriptor,
        measuredHeight: Double? = nil
    ) -> EditorRect {
        textFrame(for: descriptor.measureRequest, measuredHeight: measuredHeight)
    }

    public func lineFragments(for request: BlockMeasureRequest) -> [LineFragmentSnapshot] {
        layoutContext.lineFragments(for: request, style: style)
    }

    public func caretRect(for position: TextPosition, in request: BlockMeasureRequest)
        -> EditorRect?
    {
        guard position.blockID == request.blockID else { return nil }
        return layoutContext.caretRect(
            offset: position.offset,
            request: request,
            style: style
        ).map(EditorRect.init(cgRect:))
    }

    public func caretRect(
        for position: TextPosition,
        in descriptor: EditorTextRenderDescriptor
    ) -> EditorRect? {
        caretRect(for: position, in: descriptor.measureRequest)
    }

    public func selectionRects(for range: SlopadEngine.TextRange, in request: BlockMeasureRequest)
        -> [EditorRect]
    {
        layoutContext.selectionRects(for: range, request: request, style: style)
            .map(EditorRect.init(cgRect:))
    }

    public func selectionRects(
        for range: SlopadEngine.TextRange,
        in descriptor: EditorTextRenderDescriptor
    ) -> [EditorRect] {
        selectionRects(for: range, in: descriptor.measureRequest)
    }

    public func textPosition(at point: EditorPoint, in request: BlockMeasureRequest) -> TextPosition
    {
        let offset = layoutContext.closestTextOffset(
            to: CGPoint(x: point.x, y: point.y),
            request: request,
            style: style
        )
        return TextPosition(blockID: request.blockID, offset: offset)
    }

    // MARK: - Internal State

    private let style: TextKitEditorStyle
    private let layoutContext: TextKitLayoutContext

    init(style: TextKitEditorStyle, layoutContext: TextKitLayoutContext) {
        self.style = style
        self.layoutContext = layoutContext
    }
}
