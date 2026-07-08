import Testing

@testable import SlopadBlockLayout
import SlopadCoreModel

@Suite("BlockLayout revision 전파")
struct BlockLayoutRevisionPropagationTests {
    @Test("style revision 변경이 layout snapshot revision에 반영된다")
    func styleRevisionChangeUpdatesEditorSnapshotRevision() {
        // Given
        let document = Document.singleParagraph("A", id: "a")
        let visibleIndex = VisibleBlockIndex(document: document)
        let layoutInput = makeBlockLayoutTestInput(
            document: document,
            visibleIndex: visibleIndex,
            availableWidth: 300
        )
        let textLayouter = RecordingBlockTextLayouter()
        var blockLayout = BlockLayout()
        let baseStyleRevision = 0
        let changedStyleRevision = 1

        // When
        let baseRevision = runBlockLayoutPass(
            &blockLayout,
            input: layoutInput,
            textLayouter: textLayouter
        )
        _ = blockLayout.setStyleRevision(changedStyleRevision)
        let changedRevision = runBlockLayoutPass(
            &blockLayout,
            input: layoutInput,
            textLayouter: textLayouter
        )

        // Then
        #expect(baseRevision.styleRevision == baseStyleRevision)
        #expect(changedRevision.styleRevision == changedStyleRevision)
    }

    @Test("width revision 변경이 layout snapshot revision에 반영된다")
    func widthRevisionChangeUpdatesEditorSnapshotRevision() {
        // Given
        let document = Document.singleParagraph("A", id: "a")
        let visibleIndex = VisibleBlockIndex(document: document)
        let baseWidthRevision = 300
        let changedWidthRevision = 320
        let baseLayoutInput = makeBlockLayoutTestInput(
            document: document,
            visibleIndex: visibleIndex,
            availableWidth: 300,
            widthRevision: baseWidthRevision
        )
        let changedLayoutInput = makeBlockLayoutTestInput(
            document: document,
            visibleIndex: visibleIndex,
            availableWidth: 320,
            widthRevision: changedWidthRevision
        )
        let textLayouter = RecordingBlockTextLayouter()
        var blockLayout = BlockLayout()

        // When
        let baseRevision = runBlockLayoutPass(
            &blockLayout,
            input: baseLayoutInput,
            textLayouter: textLayouter
        )
        let changedRevision = runBlockLayoutPass(
            &blockLayout,
            input: changedLayoutInput,
            textLayouter: textLayouter
        )

        // Then
        #expect(baseRevision.widthRevision == baseWidthRevision)
        #expect(changedRevision.widthRevision == changedWidthRevision)
    }

    @Test("visible sequence revision 변경이 layout snapshot revision에 반영된다")
    func visibleSequenceRevisionChangeUpdatesEditorSnapshotRevision() {
        // Given
        let a: BlockID = "a"
        let b: BlockID = "b"
        let document = makeFlatDocument([
            Block(id: a, content: BlockContent(text: "A")),
            Block(id: b, content: BlockContent(text: "B")),
        ])
        let baseVisibleIndex = VisibleBlockIndex(
            [VisibleBlock(blockID: a, depth: 0, parentID: nil)],
            revision: 10
        )
        let changedVisibleIndex = VisibleBlockIndex(
            [
                VisibleBlock(blockID: a, depth: 0, parentID: nil),
                VisibleBlock(blockID: b, depth: 0, parentID: nil),
            ],
            revision: 11
        )
        let baseLayoutInput = makeBlockLayoutTestInput(
            document: document,
            visibleIndex: baseVisibleIndex,
            availableWidth: 300
        )
        let changedLayoutInput = makeBlockLayoutTestInput(
            document: document,
            visibleIndex: changedVisibleIndex,
            availableWidth: 300
        )
        let textLayouter = RecordingBlockTextLayouter()
        var blockLayout = BlockLayout()
        let expectedBaseVisibleSequenceRevision = 10
        let expectedChangedVisibleSequenceRevision = 11

        // When
        let baseRevision = runBlockLayoutPass(
            &blockLayout,
            input: baseLayoutInput,
            textLayouter: textLayouter
        )
        let changedRevision = runBlockLayoutPass(
            &blockLayout,
            input: changedLayoutInput,
            textLayouter: textLayouter
        )

        // Then
        #expect(
            baseRevision.visibleSequenceRevision == expectedBaseVisibleSequenceRevision)
        #expect(
            changedRevision.visibleSequenceRevision
                == expectedChangedVisibleSequenceRevision
        )
    }
}
