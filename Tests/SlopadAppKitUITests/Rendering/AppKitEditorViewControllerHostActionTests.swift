import AppKit
import Testing

import SlopadEngine
@testable import SlopadAppKitUI

@MainActor
@Suite("AppKit 공개 host action")
struct AppKitEditorViewControllerHostActionTests {
    @Test("programmatic 이동은 현재 viewport를 adapter 내부에서 주입한다")
    func performsViewportOwnedAction() throws {
        // Given
        let blockID: BlockID = "block"
        let controller = AppKitEditorViewController(
            blocks: [
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(text: "ABC")
                )
            ],
            selection: .caret(blockID: blockID, offset: 2)
        )
        controller.renderAndSyncSurface(makeFirstResponder: false)

        // When
        let update = try #require(
            controller.perform(
                .moveLeft,
                makeFirstResponder: false,
                scrollSelectionIntoView: false
            )
        )

        // Then
        #expect(update.selection == .caret(blockID: blockID, offset: 1))
        #expect(controller.snapshot?.selection == update.selection)
    }

    @Test("lifecycle 조합 확정은 responder와 viewport를 보존하고 full snapshot revision을 발행한다")
    func commitsCompositionPreservingSurface() throws {
        // Given
        let blockID: BlockID = "composition"
        let trailingBlocks = (0..<30).map { index in
            EditorBlockInput(
                id: BlockID("trailing-\(index)"),
                content: BlockContent(text: "Trailing block \(index)")
            )
        }
        let controller = AppKitEditorViewController(
            blocks: [
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(text: "AB")
                )
            ] + trailingBlocks,
            selection: .caret(blockID: blockID, offset: 1)
        )
        let window = makeHostActionWindow(controller: controller)
        controller.renderAndSyncSurface(makeFirstResponder: false)
        #expect(window.makeFirstResponder(controller.canvasView))
        controller.setMarkedTextFromNativeSurface(
            "한글",
            selectedRange: NSRange(location: 1, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
        controller.scrollDocument(to: 120)
        let originalViewport = controller.currentViewport()
        let externalResponder = HostActionFocusView(frame: .zero)
        controller.view.addSubview(externalResponder)
        #expect(window.makeFirstResponder(externalResponder))
        var callbackSnapshot: EditorDocumentSnapshot?
        controller.onUpdate = { [weak controller] update in
            guard let revision = update.committedDocumentRevision else { return }
            guard let snapshot = controller?.documentSnapshot else { return }
            #expect(snapshot.revision == revision)
            callbackSnapshot = snapshot
        }

        // When
        let update = try #require(controller.commitActiveComposition())

        // Then
        #expect(update.committedDocumentRevision?.rawValue == 1)
        #expect(controller.snapshot?.composition == nil)
        #expect(!controller.hasActiveNativeMarkedText)
        #expect(controller.currentViewport() == originalViewport)
        #expect(window.firstResponder === externalResponder)
        #expect(callbackSnapshot?.revision == update.committedDocumentRevision)
        #expect(callbackSnapshot?.blocks.first?.content.text == "A한글B")
    }
}

@MainActor
private final class HostActionFocusView: NSView {
    override var acceptsFirstResponder: Bool {
        true
    }
}

@MainActor
private func makeHostActionWindow(controller: AppKitEditorViewController) -> NSWindow {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 320, height: 140),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.contentViewController = controller
    controller.view.frame = NSRect(x: 0, y: 0, width: 320, height: 140)
    controller.view.layoutSubtreeIfNeeded()
    return window
}
