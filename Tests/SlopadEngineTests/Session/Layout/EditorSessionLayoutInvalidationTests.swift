import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 레이아웃 무효화")
struct EditorSessionLayoutInvalidationTests {
    @Test("캐시된 레이아웃 이후 명령이 문서를 바꾸면 다음 렌더링에서 다시 배치한다")
    func relayoutsAfterDocumentCommand() {
        // Given
        let blockID: BlockID = "a"
        let textLayouter = RecordingBlockTextLayouter()
        let session = EditorSession(
            document: .singleParagraph("", id: blockID),
            textLayouter: textLayouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)
        _ = session.render(in: viewport)
        textLayouter.measuredBlockIDs.removeAll()

        // When
        _ = session.handleCommand(.insertText("X"))
        _ = session.render(in: viewport)

        // Then
        #expect(textLayouter.measuredBlockIDs == [blockID])
    }

    @Test("레이아웃 스타일 리비전 변경은 세션을 통해 레이아웃을 갱신 필요로 만들고 다음 스냅샷 리비전에 반영된다")
    func appliesStyleRevisionChange() {
        // Given
        let blockID: BlockID = "a"
        let textLayouter = RecordingBlockTextLayouter()
        let session = EditorSession(
            document: .singleParagraph("Hi", id: blockID),
            textLayouter: textLayouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)
        _ = session.render(in: viewport)
        textLayouter.measuredBlockIDs.removeAll()

        // When
        let update = session.setLayoutStyleRevision(7)
        let snapshot = session.render(in: viewport)

        // Then
        #expect(update.invalidation.layoutGeometryChanged)
        #expect(snapshot.revision.styleRevision == 7)
        #expect(textLayouter.measuredBlockIDs == [blockID])
    }

    @Test("특정 블록 측정 무효화는 세션을 통해 해당 블록만 다시 측정한다")
    func invalidatesSpecificMeasurements() {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let textLayouter = RecordingBlockTextLayouter(
            measurementsByBlockID: [
                a: BlockMeasurement(height: 10),
                b: BlockMeasurement(height: 12),
            ]
        )
        let session = EditorSession(
            document: makeFlatDocument([
                Block(id: a, content: BlockContent(text: "A")),
                Block(id: b, content: BlockContent(text: "B")),
            ]),
            textLayouter: textLayouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)
        _ = session.render(in: viewport)
        textLayouter.measuredBlockIDs.removeAll()  // spy only

        // When
        let update = session.invalidateLayoutMeasurements(blockIDs: [b])
        _ = session.render(in: viewport)

        // Then
        #expect(update.invalidation.blockIDs == Set([b]))
        #expect(update.invalidation.layoutGeometryChanged)
        #expect(textLayouter.measuredBlockIDs == [b])
    }

    @Test("전체 블록 측정 무효화는 세션을 통해 모든 블록을 다시 측정한다")
    func invalidatesAllMeasurements() {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let textLayouter = RecordingBlockTextLayouter(
            measurementsByBlockID: [
                a: BlockMeasurement(height: 10),
                b: BlockMeasurement(height: 12),
            ]
        )
        let session = EditorSession(
            document: makeFlatDocument([
                Block(id: a, content: BlockContent(text: "A")),
                Block(id: b, content: BlockContent(text: "B")),
            ]),
            textLayouter: textLayouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)
        _ = session.render(in: viewport)
        textLayouter.measuredBlockIDs.removeAll()  // spy only

        // When
        let update = session.invalidateAllLayoutMeasurements()
        _ = session.render(in: viewport)

        // Then
        #expect(update.invalidation.blockIDs.isEmpty)
        #expect(update.invalidation.layoutGeometryChanged)
        #expect(textLayouter.measuredBlockIDs == [a, b])
    }
}
