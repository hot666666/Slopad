import Testing

@testable import SlopadEngine
import SlopadCoreModel

@Suite("에디터 세션 텍스트 포인터 drag 입력 이벤트")
struct EditorSessionTextPointerDragInputEventTests {
    @Test("본문 drag 포인터 이벤트는 같은 블록 안에서 텍스트 선택 범위로 해석된다")
    func handlesPointerTextSelectionDragEvent() throws {
        // Given
        let blockID: BlockID = "a"
        let layouter = SpyBlockTextLayouter()
        layouter.measurementsByBlockID = [blockID: BlockMeasurement(height: 10)]
        layouter.textPositionResolver = { blockID, point in
            TextPosition(blockID: blockID, offset: point.x < 40 ? 1 : 4)
        }
        let session = EditorSession(
            document: .singleParagraph("Body", id: blockID),
            textLayouter: layouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)

        // When
        let beginUpdate = try #require(
            session.handleInput(
                .pointer(
                    .beginTextSelection(
                        documentPoint: EditorPoint(x: 20, y: 5),
                        viewport: viewport
                    )
                )
            )
        )
        let dragUpdate = try #require(
            session.handleInput(
                .pointer(
                    .updateTextSelection(
                        documentPoint: EditorPoint(x: 80, y: 5),
                        viewport: viewport,
                        blockSelectionThreshold: nil
                    )
                )
            )
        )
        _ = try #require(session.handleInput(.pointer(.endTextSelection)))

        // Then
        #expect(beginUpdate.selection == .caret(blockID: blockID, offset: 1))
        #expect(
            dragUpdate.selection
                == .text(
                    TextSelection(
                        anchor: TextPosition(blockID: blockID, offset: 1),
                        focus: TextPosition(blockID: blockID, offset: 4)
                    )
                )
        )
        #expect(session.activeTextRange() == TextRange(1, 4))
        #expect(layouter.textPositionRequests.map(\.blockID) == [blockID, blockID])
        #expect(
            layouter.textPositionRequests.map(\.point)
                == [EditorPoint(x: 20, y: 5), EditorPoint(x: 80, y: 5)]
        )
        #expect(session.textSelectionDragAnchor == nil)
    }

    @Test("본문 text drag가 다른 블록 좌표로 넘어가도 anchor 블록 내부 텍스트 선택으로 제한된다")
    func keepsTextDragInsideAnchorBlock() throws {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let c: BlockID = "c"
        let layouter = SpyBlockTextLayouter()
        layouter.measurementsByBlockID = [
            a: BlockMeasurement(height: 10),
            b: BlockMeasurement(height: 10),
            c: BlockMeasurement(height: 10),
        ]
        layouter.textPositionResolver = { blockID, point in
            TextPosition(blockID: blockID, offset: point.y >= 10 ? 6 : 1)
        }
        let session = EditorSession(
            document: makeFlatDocument([
                Block(id: a, content: BlockContent(text: "abcdef")),
                Block(id: b, content: BlockContent(text: "B")),
                Block(id: c, content: BlockContent(text: "C")),
            ]),
            textLayouter: layouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)

        // When
        _ = try #require(
            session.handleInput(
                .pointer(
                    .beginTextSelection(
                        documentPoint: EditorPoint(x: 20, y: 5),
                        viewport: viewport
                    )
                )
            )
        )
        let boundaryUpdate = try #require(
            session.handleInput(
                .pointer(
                    .updateTextSelection(
                        documentPoint: EditorPoint(x: 20, y: 25),
                        viewport: viewport,
                        blockSelectionThreshold: nil
                    )
                )
            )
        )
        let blockDragUpdate = session.handleInput(
            .pointer(
                .extendBlockSelection(
                    documentPoint: EditorPoint(x: 20, y: 25),
                    region: .gutter,
                    viewport: viewport
                )
            )
        )

        // Then
        #expect(
            boundaryUpdate.selection
                == .text(
                    TextSelection(
                        anchor: TextPosition(blockID: a, offset: 1),
                        focus: TextPosition(blockID: a, offset: 6)
                    )
                )
        )
        #expect(session.activeTextPosition()?.blockID == a)
        #expect(session.activeTextRange() == TextRange(1, 6))
        #expect(blockDragUpdate == nil)
        #expect(session.textSelectionDragAnchor == TextPosition(blockID: a, offset: 1))
        #expect(layouter.textPositionRequests.map(\.blockID) == [a, a])
        #expect(
            layouter.textPositionRequests.map(\.point)
                == [EditorPoint(x: 20, y: 5), EditorPoint(x: 20, y: 10)]
        )
    }

    @Test("본문 text drag가 anchor block에서 한 줄 높이 이상 벗어나면 블록 선택으로 전환한다")
    func convertsTextDragToBlockSelectionAfterThreshold() throws {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let c: BlockID = "c"
        let layouter = SpyBlockTextLayouter()
        layouter.measurementsByBlockID = [
            a: BlockMeasurement(height: 10),
            b: BlockMeasurement(height: 10),
            c: BlockMeasurement(height: 10),
        ]
        layouter.textPositionResolver = { blockID, _ in
            TextPosition(blockID: blockID, offset: 1)
        }
        let session = EditorSession(
            document: makeFlatDocument([
                Block(id: a, content: BlockContent(text: "A")),
                Block(id: b, content: BlockContent(text: "B")),
                Block(id: c, content: BlockContent(text: "C")),
            ]),
            textLayouter: layouter
        )
        let viewport = EditorViewport(width: 240, scrollY: 0, height: 400)

        // When
        _ = try #require(
            session.handleInput(
                .pointer(
                    .beginTextSelection(
                        documentPoint: EditorPoint(x: 20, y: 15),
                        viewport: viewport
                    )
                )
            )
        )
        let thresholdUpdate = try #require(
            session.handleInput(
                .pointer(
                    .updateTextSelection(
                        documentPoint: EditorPoint(x: 20, y: 0),
                        viewport: viewport,
                        blockSelectionThreshold: 10
                    )
                )
            )
        )
        let continuedUpdate = try #require(
            session.handleInput(
                .pointer(
                    .extendBlockSelection(
                        documentPoint: EditorPoint(x: 0, y: 25),
                        region: .gutter,
                        viewport: viewport
                    )
                )
            )
        )

        // Then
        #expect(
            thresholdUpdate.selection
                == .blocks(BlockSelection(blockIDs: [a, b], anchor: b, focus: a))
        )
        #expect(
            continuedUpdate.selection
                == .blocks(BlockSelection(blockIDs: [b, c], anchor: b, focus: c))
        )
        #expect(session.activeTextPosition() == nil)
        #expect(session.textSelectionDragAnchor == nil)
        #expect(session.blockSelectionDragAnchor?.blockID == b)
    }
}
