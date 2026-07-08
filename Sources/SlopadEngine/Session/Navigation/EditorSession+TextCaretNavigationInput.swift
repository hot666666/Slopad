import SlopadCoreModel

// MARK: - Text Caret Navigation Input

extension EditorSession {
    func moveHorizontally(
        direction: EditorNavigationDirection,
        viewport: EditorViewport
    ) -> EditorUpdate? {
        guard direction.horizontalStep != nil else { return nil }
        if case .text(let textSelection) = editorModel.selection,
            let range = textSelection.rangeInSingleBlock
        {
            let offset = direction == .left ? range.lowerBound : range.upperBound
            return handleSelectionChange(
                .caret(blockID: textSelection.focus.blockID, offset: offset))
        }
        guard case .caret(let position) = editorModel.selection else { return nil }
        let blockID = position.blockID
        guard let block = editorModel.document.block(blockID) else { return nil }

        switch direction {
        case .left:
            if position.offset > 0 {
                return handleSelectionChange(
                    .caret(blockID: blockID, offset: position.offset - 1))
            }

        case .right:
            if position.offset < block.content.length {
                return handleSelectionChange(
                    .caret(blockID: blockID, offset: position.offset + 1))
            }

        case .up, .down:
            return nil
        }
        return moveAcrossTextBoundaryIfNeeded(direction: direction, viewport: viewport)
    }

    func moveToTextBoundary(_ direction: EditorNavigationDirection) -> EditorUpdate? {
        guard
            let position = activeTextPosition(),
            let block = editorModel.document.block(position.blockID),
            let offset = textBoundaryOffset(direction, in: block)
        else { return nil }

        guard position.offset != offset else { return nil }
        return handleSelectionChange(.caret(blockID: position.blockID, offset: offset))
    }

    func moveByWord(_ direction: EditorNavigationDirection) -> EditorUpdate? {
        guard direction.horizontalStep != nil else { return nil }
        guard
            let position = activeTextPosition(),
            let block = editorModel.document.block(position.blockID)
        else { return nil }

        let text = block.content.text
        let offset: Int
        switch direction {
        case .left:
            offset = previousSpaceDelimitedWordBoundary(in: text, from: position.offset)
        case .right:
            offset = nextSpaceDelimitedWordBoundary(in: text, from: position.offset)
        case .up, .down:
            return nil
        }
        guard position.offset != offset else { return nil }
        return handleSelectionChange(.caret(blockID: position.blockID, offset: offset))
    }

    func textBoundaryOffset(
        _ direction: EditorNavigationDirection,
        in block: Block
    ) -> Int? {
        switch direction {
        case .left:
            return 0
        case .right:
            return block.content.length
        case .up, .down:
            return nil
        }
    }
}
