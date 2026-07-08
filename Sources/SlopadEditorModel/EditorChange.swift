import SlopadCoreModel

// MARK: - EditorChange

package struct EditorChange {
    package let changedBlockIDs: Set<BlockID>
    package let operations: [EditorOperation]

    init(
        changedBlockIDs: Set<BlockID> = [],
        operations: [EditorOperation] = []
    ) {
        self.changedBlockIDs = changedBlockIDs
        self.operations = operations
    }
}
