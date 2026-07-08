// MARK: - EditorSnapshotRevision

public struct EditorSnapshotRevision: Hashable, Sendable {
    package let documentRevision: Int
    package let compositionRevision: Int
    package let styleRevision: Int
    package let widthRevision: Int
    package let visibleSequenceRevision: Int

    package init(
        documentRevision: Int,
        compositionRevision: Int,
        styleRevision: Int,
        widthRevision: Int,
        visibleSequenceRevision: Int
    ) {
        self.documentRevision = documentRevision
        self.compositionRevision = compositionRevision
        self.styleRevision = styleRevision
        self.widthRevision = widthRevision
        self.visibleSequenceRevision = visibleSequenceRevision
    }
}
