import SlopadCoreModel

// MARK: - EditorModel UndoRedo

extension EditorModel {
    package var historyAvailability: (canUndo: Bool, canRedo: Bool) {
        (!undoStack.isEmpty, !redoStack.isEmpty)
    }

    @discardableResult
    package func undo() -> Bool {
        guard let transaction = undoStack.popLast() else { return false }
        document = transaction.beforeSnapshot
        selection = transaction.selectionBefore
        redoStack.append(transaction)
        assertDocumentValidInDebug()
        return true
    }

    @discardableResult
    package func redo() -> Bool {
        guard let transaction = redoStack.popLast() else { return false }
        document = transaction.afterSnapshot
        selection = transaction.selectionAfter
        undoStack.append(transaction)
        trimUndoStackToBudget()
        assertDocumentValidInDebug()
        return true
    }

    func trimUndoStackToBudget() {
        if undoConfiguration.maxTransactions <= 0 {
            undoStack.removeAll()
            return
        }
        while undoStack.count > undoConfiguration.maxTransactions {
            undoStack.removeFirst()
        }
        guard undoConfiguration.maxEstimatedBytes > 0 else {
            undoStack.removeAll()
            return
        }
        while undoStack.count > 1
            && undoStack.reduce(0, { $0 + $1.estimatedUndoCost })
                > undoConfiguration.maxEstimatedBytes
        {
            undoStack.removeFirst()
        }
    }

    func assertDocumentValidInDebug() {
        #if DEBUG
            document.assertValidInvariants()
        #endif
    }
}
