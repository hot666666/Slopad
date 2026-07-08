import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 텍스트 경계 삭제 입력 이벤트")
struct EditorSessionTextBoundaryDeletionInputEventTests {
    @Test("Command-Delete 입력은 caret 이전 현재 블록 텍스트를 삭제한다")
    func deletesToTextStartInTextEditing() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("alpha beta", id: blockID),
            selection: .caret(blockID: blockID, offset: 6)
        )

        // When
        let update = try #require(session.handleInput(.command(.deleteToTextStart)))

        // Then
        #expect(session.document.block(blockID)?.content.text == "beta")
        #expect(update.selection == .caret(blockID: blockID, offset: 0))
        #expect(update.history.canUndo)
    }

    @Test("Option-Delete 입력은 공백 기준 이전 단어 경계부터 caret까지 삭제한다")
    func deletesToPreviousSpaceDelimitedWordBoundary() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("alpha beta gamma", id: blockID),
            selection: .caret(blockID: blockID, offset: 16)
        )

        // When
        let update = try #require(session.handleInput(.command(.deleteWordBackward)))

        // Then
        #expect(session.document.block(blockID)?.content.text == "alpha beta ")
        #expect(update.selection == .caret(blockID: blockID, offset: 11))
        #expect(update.history.canUndo)
    }

    @Test("modifier delete 입력은 텍스트 선택 범위를 먼저 삭제한다")
    func modifierDeleteRemovesSelectedTextFirst() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("alpha beta", id: blockID),
            selection: .text(
                TextSelection(
                    anchor: TextPosition(blockID: blockID, offset: 2),
                    focus: TextPosition(blockID: blockID, offset: 7)
                )
            )
        )

        // When
        let update = try #require(session.handleInput(.command(.deleteWordBackward)))

        // Then
        #expect(session.document.block(blockID)?.content.text == "aleta")
        #expect(update.selection == .caret(blockID: blockID, offset: 2))
        #expect(update.history.canUndo)
    }
}
