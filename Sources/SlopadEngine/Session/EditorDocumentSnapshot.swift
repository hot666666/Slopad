import SlopadCoreModel

// MARK: - EditorDocumentRevision

/// A monotonically increasing committed-content token scoped to one `EditorSession`.
public struct EditorDocumentRevision: RawRepresentable, Hashable, Codable, Comparable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - EditorDocumentSnapshot

/// A viewport-independent projection of the complete committed canonical document.
///
/// `revision` is monotonically increasing for the lifetime of one `EditorSession`.
/// Its revision advances only for committed canonical document mutations. Selection,
/// layout, scrolling, and live IME composition do not advance it.
public struct EditorDocumentSnapshot: Hashable, Codable, Sendable {
    public let revision: EditorDocumentRevision
    public let blocks: [EditorBlockInput]

    init(revision: EditorDocumentRevision, blocks: [EditorBlockInput]) {
        self.revision = revision
        self.blocks = blocks
    }
}
