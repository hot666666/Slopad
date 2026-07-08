import SlopadCoreModel

final class SpyBlockTextLayouter: BlockTextLayoutProtocol, @unchecked Sendable {
    var measurementsByBlockID: [BlockID: BlockMeasurement] = [:]
    var textFramesByBlockID: [BlockID: EditorRect] = [:]
    var lineFragmentsByBlockID: [BlockID: [LineFragmentSnapshot]] = [:]
    var caretRectsByPosition: [TextPosition: EditorRect] = [:]
    var textPositionsByBlockID: [BlockID: TextPosition] = [:]
    var textPositionResolver: ((BlockID, EditorPoint) -> TextPosition)?
    private(set) var textPositionRequests: [(blockID: BlockID, point: EditorPoint)] = []

    func measure(_ request: BlockMeasureRequest) -> BlockMeasurement {
        measurementsByBlockID[request.blockID]
            ?? BlockMeasurement(height: textFramesByBlockID[request.blockID]?.height ?? 20)
    }

    func textFrame(for request: BlockMeasureRequest, measuredHeight: Double?) -> EditorRect {
        textFramesByBlockID[request.blockID]
            ?? EditorRect(
                x: 0,
                y: 0,
                width: request.availableWidth,
                height: measuredHeight ?? 1
            )
    }

    func lineFragments(for request: BlockMeasureRequest) -> [LineFragmentSnapshot] {
        lineFragmentsByBlockID[request.blockID]
            ?? [
                LineFragmentSnapshot(
                    blockID: request.blockID,
                    range: TextRange(0, request.text.count),
                    rect: EditorRect(x: 0, y: 0, width: request.availableWidth, height: 10)
                )
            ]
    }

    func caretRect(for position: TextPosition, in request: BlockMeasureRequest) -> EditorRect? {
        caretRectsByPosition[position]
    }

    func selectionRects(for range: TextRange, in request: BlockMeasureRequest) -> [EditorRect] {
        []
    }

    func textPosition(at point: EditorPoint, in request: BlockMeasureRequest) -> TextPosition {
        textPositionRequests.append((request.blockID, point))
        if let textPositionResolver {
            return textPositionResolver(request.blockID, point)
        }
        return textPositionsByBlockID[request.blockID]
            ?? TextPosition(blockID: request.blockID, offset: 0)
    }
}
