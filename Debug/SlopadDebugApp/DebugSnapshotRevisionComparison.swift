import SlopadCoreModel

// MARK: - DebugSnapshotRevisionComparison

struct EditorSnapshotRevisionComparison: Hashable, Sendable {
    let hasPreviousRevision: Bool
    let documentRevision: Int
    let compositionRevision: Int
    let styleRevision: Int
    let documentChanged: Bool
    let compositionChanged: Bool
    let styleChanged: Bool
    let widthChanged: Bool
    let visibleSequenceChanged: Bool
}

extension EditorSnapshotRevision {
    func comparison(from previous: EditorSnapshotRevision?) -> EditorSnapshotRevisionComparison {
        EditorSnapshotRevisionComparison(
            hasPreviousRevision: previous != nil,
            documentRevision: documentRevision,
            compositionRevision: compositionRevision,
            styleRevision: styleRevision,
            documentChanged: previous?.documentRevision != documentRevision,
            compositionChanged: previous?.compositionRevision != compositionRevision,
            styleChanged: previous?.styleRevision != styleRevision,
            widthChanged: previous?.widthRevision != widthRevision,
            visibleSequenceChanged: previous?.visibleSequenceRevision != visibleSequenceRevision
        )
    }
}
