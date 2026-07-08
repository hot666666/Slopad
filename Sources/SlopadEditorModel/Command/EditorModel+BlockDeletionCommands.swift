import SlopadCoreModel

// MARK: - Block Deletion Commands

extension EditorModel {
    func deleteBlockSelection(
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        guard case .blocks(let blockSelection) = selection else {
            throw .abort
        }
        let ordered = document.topLevelBlockIDs(blockSelection.blockIDs)
        guard !ordered.isEmpty else { throw .abort }
        let allVisibleSelected =
            !document.rootBlockIDs.isEmpty
            && ordered == document.rootBlockIDs
        var removed: [BlockID] = []
        for blockID in ordered {
            switch document.removeSubtree(blockID) {
            case .success(let removedSubtree):
                removed.append(contentsOf: removedSubtree)

            case .failure:
                throw .abort
            }
        }
        changed.formUnion(removed)
        operations.append(.deleteBlocks(blockIDs: removed))

        if allVisibleSelected {
            let resetID = BlockID()
            document = .singleParagraph("", id: resetID)
            selection = .caret(blockID: resetID, offset: 0)
            changed.insert(resetID)
            operations.append(.resetDocumentToEmptyParagraph(blockID: resetID))
        } else {
            selection = .inactive
        }
    }
}
