import SlopadCoreModel

// MARK: - Text Content Commands

extension EditorModel {
    func insertText(
        _ text: String,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        switch selection {
        case .inactive:
            throw .abort

        case .caret(let position):
            let blockID = position.blockID
            guard document.containsBlock(blockID) else { throw .abort }
            let offset = position.offset
            try requireDocumentMutationSuccess(
                document.updateContent(blockID: blockID) { content in
                    content.insert(text, at: offset)
                })
            let newOffset = offset + text.count
            selection = .caret(blockID: blockID, offset: newOffset)
            changed.insert(blockID)
            normalizeShortcutsIfNeeded(
                blockID: blockID, caretOffset: newOffset, operations: &operations, changed: &changed
            )

        case .text(let textSelection):
            guard textSelection.isSingleBlock, let range = textSelection.rangeInSingleBlock else {
                throw .abort
            }
            let blockID = textSelection.anchor.blockID
            guard document.containsBlock(blockID) else { throw .abort }
            try requireDocumentMutationSuccess(
                document.updateContent(blockID: blockID) { content in
                    content.delete(range)
                    content.insert(text, at: range.lowerBound)
            })
            selection = .caret(blockID: blockID, offset: range.lowerBound + text.count)
            changed.insert(blockID)
            normalizeShortcutsIfNeeded(
                blockID: blockID, caretOffset: range.lowerBound + text.count,
                operations: &operations, changed: &changed)

        case .blocks:
            throw .abort
        }
    }

    func replaceText(
        blockID: BlockID,
        range: TextRange,
        text: String,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        guard !range.isEmpty || !text.isEmpty else { throw .abort }
        guard document.containsBlock(blockID) else { throw .abort }
        try requireDocumentMutationSuccess(
            document.updateContent(blockID: blockID) { content in
                content.delete(range)
                content.insert(text, at: range.lowerBound)
            })
        let newOffset = range.lowerBound + text.count
        selection = .caret(blockID: blockID, offset: newOffset)
        changed.insert(blockID)
        if !text.isEmpty {
            normalizeShortcutsIfNeeded(
                blockID: blockID, caretOffset: newOffset, operations: &operations, changed: &changed
            )
        }
    }

    func deleteText(
        blockID: BlockID,
        range: TextRange,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        guard document.containsBlock(blockID) else { throw .abort }
        try requireDocumentMutationSuccess(
            document.updateContent(blockID: blockID) { content in
                content.delete(range)
            })
        selection = .caret(blockID: blockID, offset: range.lowerBound)
        changed.insert(blockID)
    }

}
