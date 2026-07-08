import CoreGraphics
import SlopadEngine

// MARK: - TextKitEditorStyle

public struct TextKitEditorStyle: Hashable, Sendable {
    public var fontName: String
    public var fontSize: Double
    public var lineHeightMultiple: Double
    public var gutterWidth: Double
    public var contentHorizontalPadding: Double
    public var blockIndentWidth: Double

    public init(
        fontName: String = "System",
        fontSize: Double = 15,
        lineHeightMultiple: Double = 1.25,
        gutterWidth: Double = 40,
        contentHorizontalPadding: Double = 14,
        blockIndentWidth: Double = 20
    ) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.lineHeightMultiple = lineHeightMultiple
        self.gutterWidth = gutterWidth
        self.contentHorizontalPadding = contentHorizontalPadding
        self.blockIndentWidth = blockIndentWidth
    }

    func textOrigin(depth: Int, kind: BlockKind) -> CGPoint {
        let metrics = TextKitBlockChromeMetrics.metrics(for: kind)
        return CGPoint(
            x: gutterWidth + contentHorizontalPadding + Double(depth) * blockIndentWidth,
            y: metrics.topPadding
        )
    }

    func textWidth(availableWidth: Double, depth: Int) -> Double {
        let usedWidth =
            gutterWidth + contentHorizontalPadding * 2 + Double(depth) * blockIndentWidth
        return max(16, availableWidth - usedWidth)
    }
}
