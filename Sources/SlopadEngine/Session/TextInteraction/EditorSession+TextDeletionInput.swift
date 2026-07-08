import SlopadCoreModel

// MARK: - Text Deletion Input

extension EditorSession {
    func deleteBackwardToTextStart() -> EditorUpdate? {
        deleteBackward { _, _ in 0 }
    }

    func deleteBackwardToPreviousWordBoundary() -> EditorUpdate? {
        deleteBackward { block, offset in
            previousSpaceDelimitedWordBoundary(in: block.content.text, from: offset)
        }
    }

    private func deleteBackward(
        lowerBound: (Block, Int) -> Int
    ) -> EditorUpdate? {
        if let range = activeTextRange(), !range.isEmpty,
            let position = activeTextPosition()
        {
            return handleCommand(.deleteText(blockID: position.blockID, range: range))
        }

        guard
            let position = activeTextPosition(),
            let block = editorModel.document.block(position.blockID)
        else { return nil }

        let range = TextRange(lowerBound(block, position.offset), position.offset)
        guard !range.isEmpty else { return nil }
        return handleCommand(.deleteText(blockID: position.blockID, range: range))
    }
}
