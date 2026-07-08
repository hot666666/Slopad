import SlopadCoreModel

// MARK: - Block Outdent Commands

extension EditorModel {
    func outdent(
        selection blockSelection: BlockSelection,
        operations: inout [EditorOperation],
        changed: inout Set<BlockID>
    ) throws(EditorCommandAbort) {
        let ordered = document.topLevelBlockIDs(blockSelection.blockIDs)
        let moving = ordered.filter { document.parentID(of: $0) != nil }
        guard !moving.isEmpty else { throw .abort }

        var insertedAfterParentCounts: [BlockID: Int] = [:]
        var moved: [BlockID] = []
        for blockID in moving {
            guard let parentID = document.parentID(of: blockID),
                let parent = document.block(parentID)
            else { continue }
            let grandparentID = parent.parentID
            let targetSiblings = document.children(of: grandparentID)
            let parentIndex = targetSiblings.firstIndex(of: parentID) ?? targetSiblings.count - 1
            let offset = insertedAfterParentCounts[parentID, default: 0]
            let insertionIndex = min(parentIndex + 1 + offset, targetSiblings.count)

            try requireDocumentMutationSuccess(
                document.moveSubtreeRange(
                    [blockID],
                    toParentID: grandparentID,
                    index: insertionIndex
                ))
            insertedAfterParentCounts[parentID] = offset + 1
            moved.append(blockID)
        }
        guard !moved.isEmpty else { throw .abort }

        selection = .blocks(blockSelection)
        changed.formUnion(moved)
        operations.append(.outdent(blockIDs: moved))
    }
}
