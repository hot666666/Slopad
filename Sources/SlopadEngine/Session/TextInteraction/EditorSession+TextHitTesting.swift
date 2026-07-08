import SlopadCoreModel

// MARK: - EditorSession TextHitTesting

extension EditorSession {
    @discardableResult
    func focusText(
        at documentPoint: EditorPoint,
        viewport: EditorViewport
    ) -> EditorUpdate? {
        guard let position = textPosition(at: documentPoint, viewport: viewport) else {
            return nil
        }
        return handleSelectionChange(.caret(position))
    }

    func textPosition(
        at documentPoint: EditorPoint,
        viewport: EditorViewport
    ) -> TextPosition? {
        _ = preparedLayout(for: viewport)
        guard
            let rendered = renderedBlock(
                at: documentPoint,
                viewportWidth: viewport.width
            )
        else {
            return nil
        }

        let localPoint = EditorPoint(
            x: documentPoint.x - rendered.frame.x,
            y: documentPoint.y - rendered.frame.y
        )
        return textLayouter.textPosition(
            at: localPoint,
            in: rendered.textRender.measureRequest
        )
    }

    func textPosition(
        in blockID: BlockID,
        at documentPoint: EditorPoint,
        viewport: EditorViewport
    ) -> TextPosition? {
        _ = preparedLayout(for: viewport)
        guard
            let rendered = renderedBlock(
                blockID: blockID,
                viewportWidth: viewport.width
            )
        else {
            return nil
        }

        let textFrame = rendered.textRender.frame
        let clampedPoint = EditorPoint(
            x: min(max(documentPoint.x, textFrame.minX), textFrame.maxX),
            y: min(max(documentPoint.y, textFrame.minY), textFrame.maxY)
        )
        let localPoint = EditorPoint(
            x: clampedPoint.x - rendered.frame.x,
            y: clampedPoint.y - rendered.frame.y
        )
        return textLayouter.textPosition(
            at: localPoint,
            in: rendered.textRender.measureRequest
        )
    }

}
