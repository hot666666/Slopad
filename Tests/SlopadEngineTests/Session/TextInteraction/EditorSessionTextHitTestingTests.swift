import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 텍스트 hit-test")
struct EditorSessionTextHitTestingTests {
    @Test("본문 클릭 위치는 세션이 블록 내부 텍스트 위치로 해석한다")
    func focusesTextAtDocumentPoint() throws {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let geometry = SpyBlockTextLayouter()
        geometry.measurementsByBlockID = [
            a: BlockMeasurement(height: 10),
            b: BlockMeasurement(height: 14),
        ]
        geometry.textPositionsByBlockID[b] = TextPosition(blockID: b, offset: 2)
        let session = EditorSession(
            document: makeFlatDocument([
                Block(id: a, content: BlockContent(text: "A")),
                Block(id: b, content: BlockContent(text: "Body")),
            ]),
            textLayouter: geometry
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)

        // When
        let update = try #require(
            session.focusText(at: EditorPoint(x: 48, y: 12), viewport: viewport)
        )

        // Then
        #expect(update.selection == EditorSelection.caret(blockID: b, offset: 2))
        #expect(geometry.textPositionRequests.map(\.blockID) == [b])
        #expect(geometry.textPositionRequests.first?.point == EditorPoint(x: 48, y: 2))
    }
}
