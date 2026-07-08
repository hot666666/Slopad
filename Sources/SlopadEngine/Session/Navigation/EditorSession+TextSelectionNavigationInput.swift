import SlopadCoreModel

// MARK: - Text Selection Navigation Input

extension EditorSession {
    func extendTextSelection(to direction: EditorNavigationDirection) -> EditorUpdate? {
        guard
            let position = activeTextPosition(),
            let block = editorModel.document.block(position.blockID),
            let offset = textBoundaryOffset(direction, in: block)
        else { return nil }
        return extendTextSelection(blockID: position.blockID, to: offset)
    }

    func extendTextSelectionByCharacter(
        _ direction: EditorNavigationDirection
    ) -> EditorUpdate? {
        guard direction.horizontalStep != nil else { return nil }
        guard
            let position = activeTextPosition(),
            let block = editorModel.document.block(position.blockID)
        else { return nil }

        let offset: Int
        switch direction {
        case .left:
            guard position.offset > 0 else { return nil }
            offset = position.offset - 1

        case .right:
            guard position.offset < block.content.length else { return nil }
            offset = position.offset + 1
        case .up, .down:
            return nil
        }
        return extendTextSelection(blockID: position.blockID, to: offset)
    }

    func extendTextSelectionByWord(_ direction: EditorNavigationDirection) -> EditorUpdate? {
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
        return extendTextSelection(blockID: position.blockID, to: offset)
    }

    private func extendTextSelection(blockID: BlockID, to offset: Int) -> EditorUpdate? {
        let anchor: TextPosition
        switch editorModel.selection {
        case .caret(let position):
            anchor = position

        case .text(let selection) where selection.isSingleBlock:
            anchor = selection.anchor

        default:
            return nil
        }

        let focus = TextPosition(blockID: blockID, offset: offset)
        if anchor == focus {
            return handleSelectionChange(.caret(focus))
        }
        return handleSelectionChange(.text(TextSelection(anchor: anchor, focus: focus)))
    }
}
