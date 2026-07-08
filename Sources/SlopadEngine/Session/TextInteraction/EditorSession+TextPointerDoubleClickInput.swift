import SlopadCoreModel

// MARK: - EditorSession TextPointerDoubleClickInput

extension EditorSession {
    func selectWordOrAllTextFromPointer(
        at documentPoint: EditorPoint,
        viewport: EditorViewport
    ) -> EditorUpdate? {
        clearPointerDragState()
        guard
            let position = textPosition(at: documentPoint, viewport: viewport),
            let block = editorModel.document.block(position.blockID)
        else {
            return nil
        }

        let wordRange = spaceDelimitedWordRange(
            in: block.content.text,
            containing: position.offset
        )
        let fullRange = TextRange(0, block.content.length)
        let doubleClickStateMatches =
            textDoubleClickSelection?.blockID == position.blockID
            && textDoubleClickSelection?.wordRange == wordRange
        let activeRange = activeTextRange()
        let activeBlockID = activeTextPosition()?.blockID
        let activeSelectionMatchesWord =
            activeBlockID == position.blockID && activeRange == wordRange
        let activeSelectionMatchesFullText =
            activeBlockID == position.blockID && activeRange == fullRange
        let range =
            doubleClickStateMatches || activeSelectionMatchesWord || activeSelectionMatchesFullText
            ? fullRange
            : wordRange
        textDoubleClickSelection = (blockID: position.blockID, wordRange: wordRange)

        return handleSelectionChange(
            .text(
                TextSelection(
                    anchor: TextPosition(blockID: position.blockID, offset: range.lowerBound),
                    focus: TextPosition(blockID: position.blockID, offset: range.upperBound)
                )
            )
        )
    }
}
