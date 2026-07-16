import AppKit
import Foundation
import SlopadCoreModel

// MARK: - TextKitLayoutContext

final class TextKitLayoutContext: @unchecked Sendable {
    private let lock = NSLock()
    private let textStorage = NSTextStorage()
    private let textContentStorage = NSTextContentStorage()
    private let textLayoutManager = NSTextLayoutManager()
    private let textContainer = NSTextContainer(
        size: CGSize(width: 1, height: CGFloat.greatestFiniteMagnitude)
    )

    private static let trailingLineBreakSentinel = "\u{200B}"

    init() {
        textContainer.lineFragmentPadding = 0
        textContentStorage.textStorage = textStorage
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = textContainer
    }

    func measure(
        _ request: BlockMeasureRequest,
        style: TextKitEditorStyle,
        minimumHeight: CGFloat
    ) -> CGFloat {
        lock.lock()
        defer { lock.unlock() }

        prepareLayout(for: request, style: style)

        var measuredHeight: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            measuredHeight = max(measuredHeight, fragment.layoutFragmentFrame.maxY)
            return true
        }

        return max(minimumHeight, measuredHeight)
    }

    func draw(
        _ request: BlockMeasureRequest,
        in frame: CGRect,
        style: TextKitEditorStyle,
        context: CGContext
    ) {
        lock.lock()
        defer { lock.unlock() }

        prepareLayout(for: request, style: style)

        context.saveGState()
        context.translateBy(x: frame.minX, y: frame.minY)
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            fragment.draw(at: fragment.layoutFragmentFrame.origin, in: context)
            return true
        }
        context.restoreGState()
    }

    func lineFragments(
        for request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> [LineFragmentSnapshot] {
        lock.lock()
        defer { lock.unlock() }

        let layoutString = prepareLayout(for: request, style: style)
        let textOrigin = style.textOrigin(depth: request.depth, kind: request.kind)
        var fragments: [LineFragmentSnapshot] = []

        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            for line in fragment.textLineFragments {
                let rect = line.typographicBounds.offsetBy(
                    dx: fragment.layoutFragmentFrame.origin.x + textOrigin.x,
                    dy: fragment.layoutFragmentFrame.origin.y + textOrigin.y
                )
                let textRange =
                    line.characterRange.slopadTextRange(in: layoutString)?
                    .clamped(to: request.text.count)
                    ?? SlopadCoreModel.TextRange.point(0)
                fragments.append(
                    LineFragmentSnapshot(
                        blockID: request.blockID,
                        range: textRange,
                        rect: EditorRect(
                            x: Double(rect.origin.x),
                            y: Double(rect.origin.y),
                            width: Double(rect.size.width),
                            height: Double(rect.size.height)
                        )
                    )
                )
            }
            return true
        }

        return fragments
    }

    func caretRect(
        offset: Int,
        request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> CGRect? {
        lock.lock()
        defer { lock.unlock() }

        prepareLayout(for: request, style: style)
        return caretRectWithoutLock(offset: offset, request: request, style: style)
    }

    func selectionRects(
        for range: SlopadCoreModel.TextRange,
        request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> [CGRect] {
        lock.lock()
        defer { lock.unlock() }

        prepareLayout(for: request, style: style)
        let clamped = range.clamped(to: request.text.count)
        guard let textRange = nsTextRange(for: clamped, in: request.text) else { return [] }

        let textOrigin = style.textOrigin(depth: request.depth, kind: request.kind)
        var rects: [CGRect] = []
        textLayoutManager.enumerateTextSegments(
            in: textRange,
            type: .selection,
            options: []
        ) { _, rect, _, _ in
            rects.append(rect.offsetBy(dx: textOrigin.x, dy: textOrigin.y))
            return true
        }
        return rects
    }

    func closestTextOffset(
        to point: CGPoint,
        request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> Int {
        lock.lock()
        defer { lock.unlock() }

        prepareLayout(for: request, style: style)
        let textLength = request.text.count
        guard textLength > 0 else { return 0 }

        var bestOffset = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for offset in 0...textLength {
            guard let rect = caretRectWithoutLock(offset: offset, request: request, style: style)
            else { continue }
            let caretPoint = CGPoint(x: rect.midX, y: rect.midY)
            let distance = hypot(caretPoint.x - point.x, caretPoint.y - point.y)
            if distance < bestDistance {
                bestDistance = distance
                bestOffset = offset
            }
        }
        return bestOffset
    }

    @discardableResult
    private func prepareLayout(
        for request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> String {
        let attributed = TextKitAttributedStringBuilder.attributedString(for: request, style: style)
        let layoutText = Self.normalizedTrailingLineBreak(in: attributed)

        textContainer.size = CGSize(
            width: style.textWidth(
                availableWidth: request.availableWidth,
                depth: request.depth
            ),
            height: CGFloat.greatestFiniteMagnitude
        )
        textStorage.setAttributedString(layoutText)
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        return layoutText.string
    }

    private func caretRectWithoutLock(
        offset: Int,
        request: BlockMeasureRequest,
        style: TextKitEditorStyle
    ) -> CGRect? {
        let clamped = SlopadCoreModel.TextRange.point(offset).clamped(to: request.text.count)
            .lowerBound
        let nsOffset = SlopadCoreModel.TextRange.point(clamped)
            .textKitNSRange(in: request.text)
            .location
        guard
            let location = textContentStorage.location(
                textLayoutManager.documentRange.location,
                offsetBy: nsOffset
            )
        else { return nil }

        let textOrigin = style.textOrigin(depth: request.depth, kind: request.kind)
        let textRange = NSTextRange(location: location)
        var caretRect: CGRect?
        textLayoutManager.enumerateTextSegments(
            in: textRange,
            type: .standard,
            options: [.rangeNotRequired]
        ) { _, rect, _, _ in
            caretRect = rect.offsetBy(dx: textOrigin.x, dy: textOrigin.y)
            return false
        }
        if var caretRect {
            caretRect.size.width = max(1, caretRect.width)
            return caretRect
        }
        return nil
    }

    private func nsTextRange(
        for range: SlopadCoreModel.TextRange,
        in text: String
    ) -> NSTextRange? {
        let nsRange = range.textKitNSRange(in: text)
        guard
            let start = textContentStorage.location(
                textLayoutManager.documentRange.location,
                offsetBy: nsRange.location
            ),
            let end = textContentStorage.location(start, offsetBy: nsRange.length)
        else { return nil }
        return NSTextRange(location: start, end: end)
    }

    private static func normalizedTrailingLineBreak(
        in text: NSAttributedString
    ) -> NSAttributedString {
        guard text.length > 0, text.string.hasSuffix("\n") else { return text }
        let markerAttributes = text.attributes(at: text.length - 1, effectiveRange: nil)
        let normalized = NSMutableAttributedString(attributedString: text)
        normalized.append(
            NSAttributedString(string: trailingLineBreakSentinel, attributes: markerAttributes)
        )
        return normalized
    }
}
