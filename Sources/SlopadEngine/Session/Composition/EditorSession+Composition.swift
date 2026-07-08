import SlopadBlockLayout
import SlopadCoreModel
import SlopadEditorModel

// MARK: - Composition

extension EditorSession {
    func canReceiveCompositionInput(blockID: BlockID) -> Bool {
        canRouteTextCommand()
            && activeTextPosition()?.blockID == blockID
    }

    func commitCompositionForImplicitExitIfNeeded(
        compatibleWith selection: EditorSelection
    ) -> (previousSelection: EditorSelection?, invalidation: EditorUpdateInvalidation) {
        guard
            let currentComposition = composition,
            !selection.isCompatibleWithComposition(blockID: currentComposition.blockID)
        else {
            return (previousSelection: nil, invalidation: EditorUpdateInvalidation())
        }

        let clearInvalidation = clearComposition(currentComposition)
        let commit = commitCompositionText(currentComposition)
        var invalidation = clearInvalidation
        invalidation.formUnion(commit.invalidation)
        return (
            previousSelection: commit.previousSelection,
            invalidation: invalidation
        )
    }

    func setComposition(_ newComposition: TextComposition) -> EditorUpdate {
        recordCompositionRevision(newComposition.compositionRevision)
        var blockIDs: Set<BlockID> = [newComposition.blockID]
        if let composition {
            blockIDs.insert(composition.blockID)
        }
        composition = newComposition
        let layoutInvalidation = BlockLayoutInvalidation(
            blockIDs: blockIDs,
            layoutGeometryChanged: true
        )
        blockLayout.markDirty(layoutInvalidation)
        let invalidation = EditorUpdateInvalidation(
            blockIDs: blockIDs,
            layoutGeometryChanged: true
        )
        return makeEditorUpdate(invalidation: invalidation)
    }

    func endComposition(commit: Bool) -> EditorUpdate {
        guard let currentComposition = composition else {
            return makeEditorUpdate(invalidation: EditorUpdateInvalidation())
        }
        let clearInvalidation = clearComposition(currentComposition)

        guard commit else {
            return makeEditorUpdate(invalidation: clearInvalidation)
        }

        let committed = commitCompositionText(currentComposition)
        var invalidation = clearInvalidation
        invalidation.formUnion(committed.invalidation)
        return makeEditorUpdate(
            invalidation: invalidation,
            previousSelection: committed.previousSelection
        )
    }

    private func clearComposition(
        _ currentComposition: TextComposition
    ) -> EditorUpdateInvalidation {
        composition = nil
        let blockIDs: Set<BlockID> = [currentComposition.blockID]
        let layoutInvalidation = BlockLayoutInvalidation(
            blockIDs: blockIDs,
            layoutGeometryChanged: true
        )
        blockLayout.markDirty(layoutInvalidation)
        return EditorUpdateInvalidation(blockIDs: blockIDs, layoutGeometryChanged: true)
    }

    private func commitCompositionText(
        _ currentComposition: TextComposition
    ) -> (previousSelection: EditorSelection?, invalidation: EditorUpdateInvalidation) {
        applyCommandForUpdate(
            .replaceText(
                blockID: currentComposition.blockID,
                range: currentComposition.replacementRange,
                text: currentComposition.text
            )
        )
    }
}
