import SlopadBlockLayout
import SlopadCoreModel

// MARK: - EditorSession TextBoundaryNavigation

extension EditorSession {
    @discardableResult
    func moveAcrossTextBoundaryIfNeeded(
        direction: EditorNavigationDirection,
        viewport: EditorViewport
    ) -> EditorUpdate? {
        guard let horizontalStep = direction.horizontalStep else { return nil }
        guard case .caret(let position) = editorModel.selection else { return nil }
        _ = preparedLayout(for: viewport)
        guard let currentBlock = editorModel.document.block(position.blockID) else {
            return nil
        }

        switch direction {
        case .left:
            guard position.offset == 0 else { return nil }
        case .right:
            guard position.offset == currentBlock.content.length else { return nil }
        case .up, .down:
            return nil
        }

        guard
            let targetBlockID = blockLayout.visibleBlockID(
                relativeTo: position.blockID,
                by: horizontalStep,
                document: editorModel.document
            )
        else {
            return nil
        }
        let targetOffset =
            horizontalStep < 0
            ? editorModel.document.block(targetBlockID)?.content.length ?? 0
            : 0
        return handleSelectionChange(.caret(blockID: targetBlockID, offset: targetOffset))
    }
}
