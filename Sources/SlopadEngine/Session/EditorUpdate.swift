import SlopadCoreModel

// MARK: - EditorUpdate

public struct EditorUpdate: Sendable {
    public let selection: EditorSelection
    public let composition: TextComposition?
    public let history: EditorHistoryState

    // MARK: - Internal State

    let previousSelection: EditorSelection?
    #if SLOPAD_BENCHMARK_INSTRUMENTATION
    let layoutDirty: Bool
    #endif
    let invalidation: EditorUpdateInvalidation

    #if SLOPAD_BENCHMARK_INSTRUMENTATION
        init(
            selection: EditorSelection,
            previousSelection: EditorSelection? = nil,
            composition: TextComposition? = nil,
            history: EditorHistoryState,
            layoutDirty: Bool,
            invalidation: EditorUpdateInvalidation
        ) {
            self.selection = selection
            self.previousSelection = previousSelection
            self.composition = composition
            self.history = history
            self.layoutDirty = layoutDirty
            self.invalidation = invalidation
        }
    #else
        init(
            selection: EditorSelection,
            previousSelection: EditorSelection? = nil,
            composition: TextComposition? = nil,
            history: EditorHistoryState,
            invalidation: EditorUpdateInvalidation
        ) {
            self.selection = selection
            self.previousSelection = previousSelection
            self.composition = composition
            self.history = history
            self.invalidation = invalidation
        }
    #endif
}
