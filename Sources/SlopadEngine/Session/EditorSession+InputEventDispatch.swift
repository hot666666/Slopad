import SlopadCoreModel

// MARK: - Input Event Dispatch

extension EditorSession {
    @discardableResult
    public func handleInput(_ inputEvent: EditorInputEvent) -> EditorUpdate? {
        switch inputEvent {
        case .command(let command):
            return handleInputCommand(command)

        case .pointer(let pointerEvent):
            return handlePointerEvent(pointerEvent)

        case .activeTextSelectionChanged(let blockID, let selectedRange):
            return handleActiveTextSelectionChanged(blockID: blockID, selectedRange: selectedRange)

        case .beginComposition(let blockID, let replacementRange, let text),
            .updateComposition(let blockID, let replacementRange, let text):
            guard canReceiveCompositionInput(blockID: blockID) else { return nil }
            return setComposition(
                nextTextComposition(
                    blockID: blockID,
                    replacementRange: replacementRange,
                    text: text
                )
            )

        case .commitComposition:
            return endComposition(commit: true)

        case .cancelComposition:
            return endComposition(commit: false)
        }
    }
}
