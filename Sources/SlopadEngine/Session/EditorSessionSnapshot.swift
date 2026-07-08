import SlopadCoreModel

// MARK: - EditorSessionSnapshot

public struct EditorSessionSnapshot: Sendable {
    public let revision: EditorSnapshotRevision
    public let totalHeight: Double
    public let visibleBlocks: [EditorRenderedBlock]
    public let selection: EditorSelection
    public let composition: TextComposition?
    public let history: EditorHistoryState
    public let activeTextInput: EditorSessionActiveTextInputDescriptor?
    public let blockDragState: EditorBlockDragState?
    public let blockSelectionRectangleState: EditorBlockSelectionRectangleState?

    init(
        revision: EditorSnapshotRevision,
        totalHeight: Double,
        visibleBlocks: [EditorRenderedBlock],
        selection: EditorSelection,
        composition: TextComposition? = nil,
        history: EditorHistoryState,
        activeTextInput: EditorSessionActiveTextInputDescriptor? = nil,
        blockDragState: EditorBlockDragState? = nil,
        blockSelectionRectangleState: EditorBlockSelectionRectangleState? = nil
    ) {
        self.revision = revision
        self.totalHeight = totalHeight
        self.visibleBlocks = visibleBlocks
        self.selection = selection
        self.composition = composition
        self.history = history
        self.activeTextInput = activeTextInput
        self.blockDragState = blockDragState
        self.blockSelectionRectangleState = blockSelectionRectangleState
    }
}
