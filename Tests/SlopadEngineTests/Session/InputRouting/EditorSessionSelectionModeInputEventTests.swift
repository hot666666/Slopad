import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 선택 모드 입력 이벤트")
struct EditorSessionSelectionModeInputEventTests {
    @Test("inactive 상태의 텍스트 입력과 조합 입력은 문서를 변경하지 않는다")
    func ignoresTextAndCompositionInputWhenInactive() {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("A", id: blockID),
            selection: .inactive
        )

        // When
        let textUpdate = session.handleInput(.command(.insertText("!")))
        let compositionUpdate = session.handleInput(
            .beginComposition(blockID: blockID, replacementRange: TextRange.point(1), text: "?")
        )

        // Then
        #expect(textUpdate == nil)
        #expect(compositionUpdate == nil)
        #expect(session.document.block(blockID)?.content.text == "A")
        #expect(session.composition == nil)
        let snapshot = session.render(in: EditorViewport(width: 240, scrollY: 0, height: 400))
        #expect(snapshot.selection == .inactive)
    }

    @Test("블록 선택 상태의 일반 텍스트 입력과 조합 입력은 문서를 변경하지 않는다")
    func ignoresTextAndCompositionInputWhenBlockSelected() {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("A", id: blockID),
            selection: .blocks(BlockSelection(blockIDs: [blockID]))
        )

        // When
        let textUpdate = session.handleInput(.command(.insertText("!")))
        let compositionUpdate = session.handleInput(
            .beginComposition(blockID: blockID, replacementRange: TextRange.point(1), text: "?")
        )

        // Then
        #expect(textUpdate == nil)
        #expect(compositionUpdate == nil)
        #expect(session.document.block(blockID)?.content.text == "A")
        #expect(session.composition == nil)
        #expect(
            session.render(in: EditorViewport(width: 240, scrollY: 0, height: 400)).selection
                == .blocks(BlockSelection(blockIDs: [blockID]))
        )
    }

    @Test("Escape 입력은 텍스트 편집에서 현재 블록 선택, 블록 선택에서 inactive로 전환한다")
    func handlesEscapeTransitions() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(document: .singleParagraph("A", id: blockID))

        // When
        let textUpdate = try #require(session.handleInput(.command(.escape)))
        let blockUpdate = try #require(session.handleInput(.command(.escape)))
        let inactiveUpdate = session.handleInput(.command(.escape))

        // Then
        #expect(textUpdate.selection == .blocks(BlockSelection(blockIDs: [blockID])))
        #expect(blockUpdate.selection == .inactive)
        #expect(inactiveUpdate == nil)
    }

    @Test("조합 중 Escape는 조합을 commit한 뒤 현재 블록을 선택한다")
    func commitsCompositionBeforeEscapeToBlockSelection() throws {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("A", id: blockID),
            selection: .caret(blockID: blockID, offset: 1)
        )
        _ = session.handleInput(
            .beginComposition(
                blockID: blockID,
                replacementRange: TextRange.point(1),
                text: "!"
            )
        )

        // When
        let update = try #require(session.handleInput(.command(.escape)))

        // Then
        #expect(update.history.canUndo)
        #expect(session.document.block(blockID)?.content.text == "A!")
        #expect(update.selection == .blocks(BlockSelection(blockIDs: [blockID])))
        #expect(session.composition == nil)
    }

    @Test("inactive 상태의 Enter, 삭제, 들여쓰기, 방향키는 no-op이다")
    func ignoresEditingCommandsWhenInactive() {
        // Given
        let blockID: BlockID = "a"
        let session = EditorSession(
            document: .singleParagraph("A", id: blockID),
            selection: .inactive
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)

        // When
        let enter = session.handleInput(.command(.enter))
        let delete = session.handleInput(.command(.deleteBackward))
        let indent = session.handleInput(.command(.indent))
        let arrow = session.handleInput(.command(.moveDown(viewport: viewport)))

        // Then
        #expect(enter == nil)
        #expect(delete == nil)
        #expect(indent == nil)
        #expect(arrow == nil)
        #expect(session.document.block(blockID)?.content.text == "A")
        #expect(session.render(in: viewport).selection == .inactive)
    }
}
