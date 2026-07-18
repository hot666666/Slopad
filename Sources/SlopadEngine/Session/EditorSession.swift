import SlopadBlockLayout
import SlopadCoreModel
import SlopadEditorModel

// MARK: - EditorSession

/// Mutable editor runtime owned and called serially by one executor.
///
/// `EditorSession` is intentionally not `Sendable`. A host keeps the session on the
/// executor where it was created and transfers only `Sendable` input, update, and snapshot
/// values across isolation boundaries.
public final class EditorSession {
    // MARK: - Public Interface

    public convenience init(
        blocks: [EditorBlockInput],
        selection: EditorSelection? = nil,
        textLayouter: any BlockTextLayoutProtocol
    ) {
        self.init(
            document: Document(blockInputs: blocks),
            selection: selection,
            textLayouter: textLayouter
        )
    }

    // MARK: - State

    var editorModel: EditorModel
    var blockLayout: BlockLayout
    var textLayouter: any BlockTextLayoutProtocol
    var composition: TextComposition?
    var compositionSelection: TextSelection?
    var blockDrag: (blockIDs: [BlockID], dropTarget: BlockDropTarget?, dropIndicator: EditorRect?)?
    var blockSelectionRectangle: (anchor: EditorPoint, current: EditorPoint)?
    var blockSelectionDragAnchor: BlockHitTestResult?
    var textSelectionDragAnchor: TextPosition?
    var textDoubleClickSelection: (blockID: BlockID, wordRange: TextRange)?
    var textNavigationRuntimeContext: EditorSessionTextNavigationRuntimeContext?
    private var compositionRevisionCounter: Int
    #if SLOPAD_BENCHMARK_INSTRUMENTATION
        var benchmarkMetrics: EditorSessionBenchmarkMetrics
    #endif

    // MARK: - Internal Initialization

    init(
        document: Document,
        selection: EditorSelection? = nil,
        textLayouter: any BlockTextLayoutProtocol
    ) {
        self.editorModel = EditorModel(document: document, selection: selection)
        self.blockLayout = BlockLayout()
        self.textLayouter = textLayouter
        self.composition = nil
        self.compositionSelection = nil
        self.blockDrag = nil
        self.blockSelectionRectangle = nil
        self.blockSelectionDragAnchor = nil
        self.textSelectionDragAnchor = nil
        self.textDoubleClickSelection = nil
        self.textNavigationRuntimeContext = nil
        self.compositionRevisionCounter = 0
        #if SLOPAD_BENCHMARK_INSTRUMENTATION
            self.benchmarkMetrics = EditorSessionBenchmarkMetrics()
        #endif
    }

    // MARK: - Internal State

    var historyState: EditorHistoryState {
        let availability = editorModel.historyAvailability
        return EditorHistoryState(
            canUndo: availability.canUndo,
            canRedo: availability.canRedo
        )
    }

    // MARK: - Composition Revision

    func nextTextComposition(
        blockID: BlockID,
        replacementRange: TextRange,
        text: String
    ) -> TextComposition {
        compositionRevisionCounter += 1
        return TextComposition(
            blockID: blockID,
            replacementRange: replacementRange,
            text: text,
            revision: compositionRevisionCounter
        )
    }

    func recordCompositionRevision(_ revision: Int) {
        compositionRevisionCounter = max(compositionRevisionCounter, revision)
    }
}
