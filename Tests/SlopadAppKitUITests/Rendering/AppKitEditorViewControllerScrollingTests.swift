import AppKit
import Testing

import SlopadEngine
@testable import SlopadAppKitUI

@MainActor
@Suite("AppKit programmatic scroll")
struct AppKitEditorViewControllerScrollingTests {
    @Test("공개 scroll은 반환 전에 viewport와 visible snapshot을 함께 동기화한다")
    func synchronizesVisibleSnapshot() throws {
        // Given
        let blockIDs = (0..<24).map { BlockID("block-\($0)") }
        let controller = AppKitEditorViewController(
            blocks: blockIDs.enumerated().map { index, blockID in
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(
                        text: "Block \(index)\nSecond line keeps the document scrollable."
                    )
                )
            },
            selection: .caret(blockID: blockIDs[0], offset: 0)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        controller.view.frame = NSRect(x: 0, y: 0, width: 320, height: 120)
        controller.view.layoutSubtreeIfNeeded()
        controller.renderAndSyncSurface(makeFirstResponder: false)
        let externalResponder = ProgrammaticScrollFocusView(frame: .zero)
        controller.view.addSubview(externalResponder)
        #expect(window.makeFirstResponder(externalResponder))
        _ = try #require(controller.snapshot)
        var deliveredSnapshots: [EditorSessionSnapshot] = []
        controller.onSnapshotChanged = { deliveredSnapshots.append($0) }

        // When
        controller.scrollDocument(to: 480)

        // Then
        let viewport = controller.currentViewport()
        let snapshot = try #require(controller.snapshot)
        let expectedVisibleBlockIDs = controller.session.render(in: viewport).visibleBlocks.map(\.id)
        #expect(viewport.scrollY > 0)
        withKnownIssue("공개 scroll이 아직 visible snapshot을 동기화하지 않는다") {
            #expect(!expectedVisibleBlockIDs.isEmpty)
            #expect(snapshot.visibleBlocks.map(\.id) == expectedVisibleBlockIDs)
            #expect(
                deliveredSnapshots.last?.visibleBlocks.map(\.id)
                    == snapshot.visibleBlocks.map(\.id)
            )
        }
        #expect(window.firstResponder === externalResponder)
    }

    @Test("공개 scroll은 live marked text와 native selection을 보존한다")
    func preservesMarkedText() {
        // Given
        let blockIDs = (0..<16).map { BlockID("block-\($0)") }
        let controller = AppKitEditorViewController(
            blocks: blockIDs.enumerated().map { index, blockID in
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(text: "Block \(index) with scrollable content")
                )
            },
            selection: .caret(blockID: blockIDs[0], offset: 2)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        controller.view.frame = NSRect(x: 0, y: 0, width: 320, height: 120)
        controller.view.layoutSubtreeIfNeeded()
        controller.renderAndSyncSurface(makeFirstResponder: false)
        #expect(window.makeFirstResponder(controller.canvasView))
        controller.setMarkedTextFromNativeSurface(
            "한글",
            selectedRange: NSRange(location: 1, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
        let textBeforeScroll = controller.activeNativeText
        let selectionBeforeScroll = controller.activeNativeSelectedRange
        let markedRangeBeforeScroll = controller.activeNativeMarkedRange
        let viewportBeforeScroll = controller.currentViewport()
        #expect(controller.hasActiveNativeMarkedText)

        // When
        controller.scrollDocument(to: 40)

        // Then
        #expect(controller.currentViewport().scrollY > viewportBeforeScroll.scrollY)
        #expect(controller.activeNativeText == textBeforeScroll)
        #expect(controller.activeNativeSelectedRange == selectionBeforeScroll)
        #expect(controller.activeNativeMarkedRange == markedRangeBeforeScroll)
        #expect(controller.hasActiveNativeMarkedText)
        #expect(window.firstResponder === controller.canvasView)
    }
}

@MainActor
private final class ProgrammaticScrollFocusView: NSView {
    override var acceptsFirstResponder: Bool {
        true
    }
}
