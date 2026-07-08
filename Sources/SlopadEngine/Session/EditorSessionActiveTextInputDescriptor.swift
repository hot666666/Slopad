import SlopadCoreModel

// MARK: - EditorSessionActiveTextInputDescriptor

public struct EditorSessionActiveTextInputDescriptor: Sendable {
    public let selectedRange: TextRange
    public let focusOffset: Int
    public let renderDescriptor: EditorTextRenderDescriptor

    init(
        selectedRange: TextRange,
        focusOffset: Int? = nil,
        renderDescriptor: EditorTextRenderDescriptor
    ) {
        self.selectedRange = selectedRange
        self.focusOffset = focusOffset ?? selectedRange.upperBound
        self.renderDescriptor = renderDescriptor
    }
}
