import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 클립보드 입력 이벤트")
struct EditorSessionClipboardInputEventTests {
    @Test("텍스트 선택과 블록 선택은 클립보드용 plain text로 노출된다")
    func exposesSelectedPlainText() {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let document = makeFlatDocument([
            Block(id: a, content: BlockContent(text: "Hello")),
            Block(id: b, content: BlockContent(text: "World")),
        ])
        let textSelectionSession = EditorSession(
            document: document,
            selection: .text(
                TextSelection(
                    anchor: TextPosition(blockID: a, offset: 1),
                    focus: TextPosition(blockID: a, offset: 4)
                )
            )
        )
        let blockSelectionSession = EditorSession(
            document: document,
            selection: .blocks(BlockSelection(blockIDs: [a, b]))
        )

        // When
        let selectedText = textSelectionSession.selectedPlainText()
        let selectedBlocksText = blockSelectionSession.selectedPlainText()

        // Then
        #expect(selectedText == "ell")
        #expect(selectedBlocksText == "Hello\nWorld")
    }

    @Test("pasteText 명령은 활성 텍스트 선택 범위를 붙여넣은 문자열로 교체한다")
    func pastesTextIntoActiveTextSelection() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("Hello", id: blockID),
            selection: .text(
                TextSelection(
                    anchor: TextPosition(blockID: blockID, offset: 1),
                    focus: TextPosition(blockID: blockID, offset: 4)
                )
            )
        )

        // When
        let update = try #require(session.handleInput(.command(.pasteText("i"))))

        // Then
        #expect(update.history.canUndo)
        #expect(session.document.block(blockID)?.content.text == "Hio")
        #expect(session.activeTextRange() == TextRange.point(2))
    }

    @Test("cutSelection 명령은 caret만 있을 때 앞 글자를 지우지 않는다")
    func cutSelectionDoesNotDeleteFromCaret() {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("Hello", id: blockID),
            selection: .caret(blockID: blockID, offset: 3)
        )

        // When
        let update = session.handleInput(.command(.cutSelection))

        // Then
        #expect(update == nil)
        #expect(session.document.block(blockID)?.content.text == "Hello")
        #expect(session.activeTextRange() == TextRange.point(3))
    }

    @Test("cutSelection 명령은 활성 텍스트 선택 범위를 삭제한다")
    func cutsActiveTextSelection() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("Hello", id: blockID),
            selection: .text(
                TextSelection(
                    anchor: TextPosition(blockID: blockID, offset: 1),
                    focus: TextPosition(blockID: blockID, offset: 4)
                )
            )
        )

        // When
        let update = try #require(session.handleInput(.command(.cutSelection)))

        // Then
        #expect(update.history.canUndo)
        #expect(session.document.block(blockID)?.content.text == "Ho")
        #expect(session.activeTextRange() == TextRange.point(1))
    }

    @Test("undo와 redo 입력 명령은 session history를 통해 문서와 selection을 복원한다")
    func handlesUndoRedoInputCommands() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(document: .singleParagraph("", id: blockID))
        _ = try #require(session.handleInput(.command(.insertText("Hi"))))

        // When
        let undoUpdate = try #require(session.handleInput(.command(.undo)))
        let textAfterUndo = session.document.block(blockID)?.content.text
        let redoUpdate = try #require(session.handleInput(.command(.redo)))

        // Then
        #expect(textAfterUndo == "")
        #expect(undoUpdate.selection == .caret(blockID: blockID, offset: 0))
        #expect(!undoUpdate.history.canUndo)
        #expect(undoUpdate.history.canRedo)
        #expect(undoUpdate.invalidation.layoutGeometryChanged)
        #expect(redoUpdate.selection == .caret(blockID: blockID, offset: 2))
        #expect(redoUpdate.history.canUndo)
        #expect(!redoUpdate.history.canRedo)
        #expect(session.document.block(blockID)?.content.text == "Hi")
    }
}
