import SlopadCoreModel

// MARK: - EditorTransaction

struct EditorTransaction {
    let beforeSnapshot: Document
    let afterSnapshot: Document
    let selectionBefore: EditorSelection
    let selectionAfter: EditorSelection
    let change: EditorChange

    init(
        beforeSnapshot: Document,
        afterSnapshot: Document,
        selectionBefore: EditorSelection,
        selectionAfter: EditorSelection,
        change: EditorChange
    ) {
        self.beforeSnapshot = beforeSnapshot
        self.afterSnapshot = afterSnapshot
        self.selectionBefore = selectionBefore
        self.selectionAfter = selectionAfter
        self.change = change
    }

    var estimatedUndoCost: Int {
        beforeSnapshot.estimatedStorageBytes
            + afterSnapshot.estimatedStorageBytes
            + change.operations.count * 96
            + change.changedBlockIDs.reduce(0) { $0 + $1.rawValue.utf8.count + 16 }
    }
}
