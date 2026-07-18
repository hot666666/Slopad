import AppKit
import SlopadAppKitTextKit
import SlopadAppKitUI
import SlopadEngine

@MainActor
private struct HostChromeRenderer: AppKitBlockChromeRenderer {
    func drawChrome(_ context: AppKitBlockChromeRenderContext) {
        let width = min(CGFloat(context.style.gutterWidth), context.blockFrame.width)
        let gutter = CGRect(
            x: context.blockFrame.minX,
            y: context.blockFrame.minY,
            width: width,
            height: context.blockFrame.height
        )
        let color = context.isSelected
            ? NSColor.selectedContentBackgroundColor
            : NSColor.separatorColor
        context.graphicsContext.setFillColor(color.cgColor)
        context.graphicsContext.fill(gutter)
    }
}

@main
@MainActor
private struct DownstreamAppKitHost {
    static func main() {
        let blockID: BlockID = "fixture-root"
        let style = TextKitEditorStyle(
            fontName: "System",
            fontSize: 17,
            lineHeightMultiple: 1.3,
            gutterWidth: 48,
            contentHorizontalPadding: 16,
            blockIndentWidth: 22,
            languageIdentifier: "en-US"
        )
        let controller = AppKitEditorViewController(
            blocks: [
                EditorBlockInput(
                    id: blockID,
                    kind: .todo(isChecked: false),
                    content: BlockContent(text: "Public-only downstream host")
                )
            ],
            selection: .caret(blockID: blockID, offset: 0),
            style: style,
            blockChromeRenderer: HostChromeRenderer()
        )

        exercisePublicHostContract(controller, blockID: blockID, style: style)
    }

    private static func exercisePublicHostContract(
        _ controller: AppKitEditorViewController,
        blockID: BlockID,
        style: TextKitEditorStyle
    ) {
        controller.onSnapshotChanged = { _ in }
        controller.onUpdate = { _ in }
        controller.blockChromeRenderer = HostChromeRenderer()
        _ = controller.editorStyle == style
        _ = controller.snapshot
        let viewport = controller.currentViewport()

        controller.renderAndSyncSurface(makeFirstResponder: false)
        controller.updateEditorStyle(
            TextKitEditorStyle(
                fontName: style.fontName,
                fontSize: style.fontSize + 1,
                lineHeightMultiple: style.lineHeightMultiple,
                gutterWidth: style.gutterWidth,
                contentHorizontalPadding: style.contentHorizontalPadding,
                blockIndentWidth: style.blockIndentWidth,
                languageIdentifier: style.languageIdentifier
            )
        )
        controller.focus(blockID: blockID, offset: 0)
        controller.replaceActiveText("Updated by the host")
        _ = controller.handleInput(
            .activeTextSelectionChanged(
                blockID: blockID,
                selectedRange: .point(0)
            ),
            makeFirstResponder: false,
            scrollSelectionIntoView: false
        )
        let viewportTextCommands: [EditorInputEvent.Command] = [
            .deleteWordBackward(viewport: viewport),
            .moveWordLeft(viewport: viewport),
            .moveWordRight(viewport: viewport),
            .extendCharacterLeft(viewport: viewport),
            .extendCharacterRight(viewport: viewport),
            .extendWordLeft(viewport: viewport),
            .extendWordRight(viewport: viewport),
        ]
        for command in viewportTextCommands {
            _ = controller.handleInput(
                .command(command),
                makeFirstResponder: false,
                scrollSelectionIntoView: false
            )
        }
        controller.scrollDocument(to: 0)
        controller.resetDocument(
            blocks: [
                EditorBlockInput(
                    id: blockID,
                    content: BlockContent(text: "Reset by the host")
                )
            ],
            selection: .caret(blockID: blockID, offset: 0)
        )
    }
}
