import SlopadCoreModel

// MARK: - Inline Style Commands

extension EditorModel {
    func applyTextStyle(
        blockID: BlockID,
        range: TextRange,
        style: BlockContent.InlineMark.Kind,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        guard let block = document.block(blockID) else { throw .abort }
        let originalContent = block.content
        var nextContent = originalContent
        nextContent.addMark(kind: style, range: range)
        guard nextContent.marks != originalContent.marks else {
            throw .abort
        }
        try requireDocumentMutationSuccess(
            document.replaceContent(blockID: blockID, content: nextContent))
        changed.insert(blockID)
    }

    func clearTextStyles(
        blockID: BlockID,
        range: TextRange,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        guard let block = document.block(blockID) else { throw .abort }
        let originalContent = block.content
        var nextContent = originalContent
        nextContent.clearMarks(in: range)
        guard nextContent.marks != originalContent.marks else {
            throw .abort
        }
        try requireDocumentMutationSuccess(
            document.replaceContent(blockID: blockID, content: nextContent))
        changed.insert(blockID)
    }
}
