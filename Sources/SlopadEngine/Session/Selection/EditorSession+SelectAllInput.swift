import SlopadBlockLayout
import SlopadCoreModel

// MARK: - Select All Input

extension EditorSession {
    func handleSelectAllInputCommand() -> EditorUpdate? {
        switch editorModel.selection {
        case .caret(let position):
            return selectActiveBlockTextOrEscalate(blockID: position.blockID)

        case .text(let textSelection) where textSelection.isSingleBlock:
            return selectActiveBlockTextOrEscalate(blockID: textSelection.focus.blockID)

        case .inactive, .blocks, .text:
            return selectAllVisibleBlocks()
        }
    }

    private func selectActiveBlockTextOrEscalate(blockID: BlockID) -> EditorUpdate? {
        guard let block = editorModel.document.block(blockID) else { return nil }
        let fullRange = TextRange(0, block.content.length)
        if isActiveBlockTextFullySelected(blockID: blockID, range: fullRange) {
            return selectAllVisibleBlocks()
        }
        return handleSelectionChange(
            .text(
                TextSelection(
                    anchor: TextPosition(blockID: blockID, offset: fullRange.lowerBound),
                    focus: TextPosition(blockID: blockID, offset: fullRange.upperBound)
                )
            )
        )
    }

    private func isActiveBlockTextFullySelected(blockID: BlockID, range: TextRange) -> Bool {
        guard case .text(let selection) = editorModel.selection,
            selection.isSingleBlock,
            selection.focus.blockID == blockID
        else {
            return false
        }
        return selection.rangeInSingleBlock == range
    }

    private func selectAllVisibleBlocks() -> EditorUpdate? {
        guard
            let selection = blockLayout.allVisibleBlockSelection(document: editorModel.document)
        else { return nil }
        guard editorModel.selection != .blocks(selection) else { return nil }
        return handleSelectionChange(.blocks(selection))
    }
}
