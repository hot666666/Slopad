import SlopadCoreModel

// MARK: - Invalidation

extension BlockLayout {
    package var isDirty: Bool {
        !dirtyInvalidation.blockIDs.isEmpty
            || dirtyInvalidation.visibleSequenceChanged
            || dirtyInvalidation.layoutGeometryChanged
    }

    package func hasPreparedLayout(for viewport: EditorViewport) -> Bool {
        currentRevision != nil && widthRevision == viewport.widthRevision
    }

    package mutating func markDirty(_ invalidation: BlockLayoutInvalidation) {
        dirtyInvalidation.formUnion(invalidation)
    }

    package mutating func setStyleRevision(_ revision: Int) -> Bool {
        guard styleRevision != revision else { return false }
        styleRevision = revision
        cache.invalidateAll()
        markDirty(BlockLayoutInvalidation(layoutGeometryChanged: true))
        return true
    }

    package mutating func invalidateMeasurements(blockIDs: Set<BlockID>) {
        guard !blockIDs.isEmpty else { return }
        for blockID in blockIDs {
            cache.invalidate(blockID: blockID)
        }
        markDirty(BlockLayoutInvalidation(blockIDs: blockIDs, layoutGeometryChanged: true))
    }

    package mutating func invalidateAllMeasurements() {
        cache.invalidateAll()
        markDirty(BlockLayoutInvalidation(layoutGeometryChanged: true))
    }
}
