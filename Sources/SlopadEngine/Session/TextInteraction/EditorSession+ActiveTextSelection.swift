import SlopadCoreModel

// MARK: - EditorSession ActiveTextSelection

extension EditorSession {
    func activeTextSelection() -> (position: TextPosition, range: TextRange)? {
        switch editorModel.selection {
        case .inactive:
            return nil

        case .caret(let position):
            return (position: position, range: .point(position.offset))

        case .text(let selection):
            guard
                selection.isSingleBlock,
                let range = selection.rangeInSingleBlock
            else {
                return nil
            }
            return (position: selection.focus, range: range)

        case .blocks:
            return nil
        }
    }

    func activeTextPosition() -> TextPosition? {
        activeTextSelection()?.position
    }

    func activeTextRange() -> TextRange? {
        activeTextSelection()?.range
    }
}
