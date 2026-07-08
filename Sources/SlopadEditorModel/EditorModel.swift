import SlopadCoreModel

// MARK: - EditorModel

package final class EditorModel {
    package internal(set) var document: Document
    package internal(set) var selection: EditorSelection
    let undoConfiguration: EditorUndoConfiguration
    var undoStack: [EditorTransaction]
    var redoStack: [EditorTransaction]

    package convenience init(
        document: Document,
        selection: EditorSelection? = nil
    ) {
        self.init(
            document: document,
            selection: selection,
            undoConfiguration: EditorUndoConfiguration()
        )
    }

    init(
        document: Document,
        selection: EditorSelection? = nil,
        undoConfiguration: EditorUndoConfiguration = EditorUndoConfiguration()
    ) {
        self.document = document
        self.undoConfiguration = undoConfiguration
        if let selection {
            self.selection = selection
        } else if let firstID = document.rootBlockIDs.first {
            self.selection = .caret(
                blockID: firstID, offset: document.block(firstID)?.content.length ?? 0)
        } else {
            let id = BlockID()
            self.document = Document.singleParagraph("", id: id)
            self.selection = .caret(blockID: id, offset: 0)
        }
        self.undoStack = []
        self.redoStack = []
    }
}
