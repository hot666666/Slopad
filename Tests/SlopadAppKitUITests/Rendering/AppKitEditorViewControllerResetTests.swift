import AppKit
import Testing

import SlopadEngine
@testable import SlopadAppKitUI

@MainActor
@Suite("AppKit 문서 reset")
struct AppKitEditorViewControllerResetTests {
    @Test("공개 reset은 반환 전에 새 문서와 native surface를 함께 동기화한다")
    func synchronizesSurface() throws {
        // Given
        let oldBlockID: BlockID = "old"
        let newBlockIDs = (0..<40).map { BlockID("new-\($0)") }
        let controller = AppKitEditorViewController(
            blocks: [
                EditorBlockInput(
                    id: oldBlockID,
                    content: BlockContent(text: "Old document")
                )
            ],
            selection: .caret(blockID: oldBlockID, offset: 0)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        controller.view.layoutSubtreeIfNeeded()
        controller.renderAndSyncSurface(makeFirstResponder: false)
        let oldCanvasHeight = controller.canvasView.frame.height
        #expect(window.makeFirstResponder(controller.canvasView))
        controller.canvasView.needsDisplay = false
        var deliveredSnapshots: [EditorSessionSnapshot] = []
        controller.onSnapshotChanged = { deliveredSnapshots.append($0) }

        // When
        controller.resetDocument(
            blocks: newBlockIDs.enumerated().map { index, blockID in
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(text: "New block \(index)")
                )
            },
            selection: .caret(blockID: newBlockIDs[0], offset: 3)
        )

        // Then
        _ = window
        withKnownIssue(
            "공개 reset이 아직 새 snapshot과 native surface를 동기화하지 않는다"
        ) {
            #expect(controller.snapshot != nil)
        }
        guard let snapshot = controller.snapshot else { return }
        #expect(snapshot.selection == .caret(blockID: newBlockIDs[0], offset: 3))
        #expect(snapshot.visibleBlocks.contains { $0.id == newBlockIDs[0] })
        #expect(snapshot.visibleBlocks.allSatisfy { $0.id != oldBlockID })
        #expect(controller.canvasView.frame.height > oldCanvasHeight)
        #expect(controller.canvasView.needsDisplay)
        #expect(controller.activeNativeText == "New block 0")
        #expect(controller.activeNativeSelectedRange == NSRange(location: 3, length: 0))
        #expect(deliveredSnapshots.last?.selection == snapshot.selection)
        #expect(
            deliveredSnapshots.last?.visibleBlocks.map(\.id)
                == snapshot.visibleBlocks.map(\.id)
        )
        #expect(window.firstResponder === controller.canvasView)
    }

    @Test("공개 reset은 외부 responder의 focus를 빼앗지 않는다")
    func preservesExternalResponder() {
        // Given
        let oldBlockID: BlockID = "old"
        let newBlockID: BlockID = "new"
        let controller = AppKitEditorViewController(
            blocks: [EditorBlockInput(id: oldBlockID, content: BlockContent(text: "Old"))],
            selection: .caret(blockID: oldBlockID, offset: 0)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        controller.view.layoutSubtreeIfNeeded()
        controller.renderAndSyncSurface(makeFirstResponder: false)
        let externalResponder = ResetFocusView(frame: .zero)
        controller.view.addSubview(externalResponder)
        #expect(window.makeFirstResponder(externalResponder))

        // When
        controller.resetDocument(
            blocks: [EditorBlockInput(id: newBlockID, content: BlockContent(text: "New"))],
            selection: .caret(blockID: newBlockID, offset: 0)
        )

        // Then
        #expect(window.firstResponder === externalResponder)
    }
}

@MainActor
private final class ResetFocusView: NSView {
    override var acceptsFirstResponder: Bool {
        true
    }
}
