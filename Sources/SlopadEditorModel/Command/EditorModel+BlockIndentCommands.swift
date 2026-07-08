import SlopadCoreModel

// MARK: - Block Indent Commands

extension EditorModel {
    func indent(
        selection blockSelection: BlockSelection,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        let moving = document.topLevelBlockIDs(blockSelection.blockIDs)
        guard let first = moving.first else {
            throw .abort
        }
        let parentID = document.parentID(of: first)
        let siblings = document.children(of: parentID)
        guard let firstSiblingIndex = siblings.firstIndex(of: first), firstSiblingIndex > 0 else {
            throw .abort
        }
        let newParentID = siblings[firstSiblingIndex - 1]
        guard !moving.contains(newParentID), document.containsBlock(newParentID) else {
            throw .abort
        }
        guard document.parentID(of: first) != newParentID else {
            throw .abort
        }
        try requireDocumentMutationSuccess(
            document.moveSubtreeRange(
                moving,
                toParentID: newParentID,
                index: document.children(of: newParentID).count
            ))
        selection = .blocks(blockSelection)
        changed.formUnion(moving)
        changed.insert(newParentID)
        operations.append(.indent(blockIDs: moving))
    }
}
