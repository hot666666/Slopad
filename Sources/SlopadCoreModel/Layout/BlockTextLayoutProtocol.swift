// MARK: - BlockTextLayoutProtocol

public protocol BlockTextLayoutProtocol: Sendable {
    func measure(_ request: BlockMeasureRequest) -> BlockMeasurement
    func textFrame(for request: BlockMeasureRequest, measuredHeight: Double?) -> EditorRect
    func lineFragments(for request: BlockMeasureRequest) -> [LineFragmentSnapshot]
    func caretRect(for position: TextPosition, in request: BlockMeasureRequest) -> EditorRect?
    func selectionRects(for range: TextRange, in request: BlockMeasureRequest) -> [EditorRect]
    func textPosition(at point: EditorPoint, in request: BlockMeasureRequest) -> TextPosition
}
