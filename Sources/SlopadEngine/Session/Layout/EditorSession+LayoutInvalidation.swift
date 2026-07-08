import SlopadCoreModel

// MARK: - Layout Invalidation

extension EditorSession {
    @discardableResult
    func setLayoutStyleRevision(_ revision: Int) -> EditorUpdate {
        guard blockLayout.setStyleRevision(revision) else {
            return makeEditorUpdate(invalidation: EditorUpdateInvalidation())
        }
        return makeEditorUpdate(
            invalidation: EditorUpdateInvalidation(layoutGeometryChanged: true)
        )
    }

    @discardableResult
    func invalidateLayoutMeasurements(blockIDs: Set<BlockID>) -> EditorUpdate {
        guard !blockIDs.isEmpty else {
            return makeEditorUpdate(invalidation: EditorUpdateInvalidation())
        }
        blockLayout.invalidateMeasurements(blockIDs: blockIDs)
        return makeEditorUpdate(
            invalidation: EditorUpdateInvalidation(blockIDs: blockIDs, layoutGeometryChanged: true)
        )
    }

    @discardableResult
    func invalidateAllLayoutMeasurements() -> EditorUpdate {
        blockLayout.invalidateAllMeasurements()
        return makeEditorUpdate(
            invalidation: EditorUpdateInvalidation(layoutGeometryChanged: true)
        )
    }
}
