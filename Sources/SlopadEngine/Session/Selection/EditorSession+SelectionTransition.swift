import SlopadCoreModel

// MARK: - Selection Transition

extension EditorSession {
    func handleActiveTextSelectionChanged(
        blockID: BlockID,
        selectedRange: TextRange
    ) -> EditorUpdate {
        if activeTextPosition()?.blockID == blockID,
            activeTextRange() == selectedRange
        {
            return makeEditorUpdate(invalidation: EditorUpdateInvalidation())
        }

        let selection: EditorSelection
        if selectedRange.isEmpty {
            selection = .caret(blockID: blockID, offset: selectedRange.lowerBound)
        } else {
            selection = .text(
                TextSelection(
                    anchor: TextPosition(blockID: blockID, offset: selectedRange.lowerBound),
                    focus: TextPosition(blockID: blockID, offset: selectedRange.upperBound)
                )
            )
        }
        return handleSelectionChange(selection)
    }

    func handleBlockSelection(
        anchor: BlockHitTestResult,
        focus: BlockHitTestResult
    ) -> EditorUpdate {
        guard let blockSelection = blockSelection(from: anchor, to: focus) else {
            return makeEditorUpdate(invalidation: EditorUpdateInvalidation())
        }
        return handleSelectionChange(.blocks(blockSelection))
    }

    func handleSelectionChange(_ selection: EditorSelection) -> EditorUpdate {
        let compositionExit = commitCompositionForImplicitExitIfNeeded(compatibleWith: selection)
        let previousSelection = editorModel.selection
        editorModel.replaceSelection(selection)
        return makeEditorUpdate(
            invalidation: compositionExit.invalidation,
            previousSelection: previousSelection
        )
    }
}
