import SlopadCoreModel
import SlopadEditorModel

// MARK: - EditorSession IndentInput

extension EditorSession {
    func handleIndentInputCommand() -> EditorUpdate? {
        handleIndentationInput(
            textCommand: { blockID, selectedRange in
                .indentText(blockID: blockID, range: selectedRange)
            },
            blockCommand: { blockSelection in
                .indentBlock(blockSelection)
            }
        )
    }

    func handleOutdentInputCommand() -> EditorUpdate? {
        handleIndentationInput(
            textCommand: { blockID, selectedRange in
                .outdentText(blockID: blockID, range: selectedRange)
            },
            blockCommand: { blockSelection in
                .outdentBlock(blockSelection)
            }
        )
    }

    private func handleIndentationInput(
        textCommand: (BlockID, TextRange) -> EditorCommand,
        blockCommand: (BlockSelection) -> EditorCommand
    ) -> EditorUpdate? {
        switch editorModel.selection {
        case .caret, .text:
            guard
                canRouteTextCommand(),
                let activeSelection = activeTextSelection()
            else { return nil }
            return handleCommand(
                textCommand(activeSelection.position.blockID, activeSelection.range)
            )

        case .blocks(let blockSelection):
            return handleCommand(blockCommand(blockSelection))
        case .inactive:
            return nil
        }
    }
}
