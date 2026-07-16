import AppKit
import Foundation
import SlopadAppKitTextKit
import SlopadEngine

// MARK: - AppKitEditorViewController

@MainActor
public final class AppKitEditorViewController: NSViewController {
    // MARK: - Private Types

    private enum UX {
        static let initialViewSize = NSSize(width: 920, height: 680)
        static let minimumViewportDimension: CGFloat = 1
        static let documentBottomPadding: CGFloat = 40
        static let selectionRevealPadding: CGFloat = 24
        static let scrollEpsilon: CGFloat = 0.5
        static let dropIndicatorHorizontalInset: CGFloat = 12
        static let blockSelectionFillAlpha: CGFloat = 0.18
        static let blockSelectionStrokeAlpha: CGFloat = 0.72
        static let blockSelectionStrokeInset: CGFloat = 0.5
        static let blockSelectionStrokeWidth: CGFloat = 1
        static let lineFragmentHitOutsetX: CGFloat = 4
        static let lineFragmentHitOutsetY: CGFloat = 3
    }

    // MARK: - Public State

    public let editorStyle: TextKitEditorStyle
    public let scrollView = NSScrollView()
    public private(set) var session: EditorSession
    public private(set) var snapshot: EditorSessionSnapshot?
    public var blockChromeRenderer: any AppKitBlockChromeRenderer
    public var onSnapshotChanged: ((EditorSessionSnapshot) -> Void)?
    public var onUpdate: ((EditorUpdate) -> Void)?
    package var onDrawOverlay: ((NSRect, EditorSessionSnapshot) -> Void)?
    package var onDrawCompleted: ((NSRect, UInt64) -> Void)?

    var canvasView: AppKitEditorCanvasView {
        editorCanvasView
    }

    // MARK: - Private State

    private let textLayouter: TextKitBlockTextLayouter
    private let textRenderer: TextKitBlockRenderer
    private let textInputDecorationRenderer: AppKitTextInputDecorationRenderer
    private lazy var editorCanvasView = AppKitEditorCanvasView(handler: self)
    private lazy var activeInputController = AppKitActiveInputController(owner: self)
    private lazy var dragAutoscrollController = AppKitDragAutoscrollController(
        visibleBounds: { [weak self] in
            self?.currentViewportBounds() ?? .zero
        },
        documentHeight: { [weak self] in
            self?.editorCanvasView.frame.height ?? 0
        },
        scrollToY: { [weak self] targetY in
            self?.scrollDocumentForDragAutoscroll(to: targetY)
        },
        applyDragUpdate: { [weak self] kind, documentPoint in
            self?.applyDragUpdate(kind: kind, documentPoint: documentPoint) ?? false
        }
    )
    private var isAdjustingScrollPosition = false
    private let focusOnAppear: Bool

    // MARK: - Init

    public init(
        blocks: [EditorBlockInput],
        selection: EditorSelection? = nil,
        style: TextKitEditorStyle = TextKitEditorStyle(),
        blockChromeRenderer: any AppKitBlockChromeRenderer = AppKitDefaultBlockChromeRenderer(),
        focusOnAppear: Bool = false
    ) {
        let textLayouter = TextKitBlockTextLayouter(style: style)
        self.editorStyle = style
        self.textLayouter = textLayouter
        self.textRenderer = TextKitBlockRenderer(style: style)
        self.textInputDecorationRenderer = AppKitTextInputDecorationRenderer(
            textLayouter: textLayouter
        )
        self.session = EditorSession(
            blocks: blocks,
            selection: selection,
            textLayouter: textLayouter
        )
        self.blockChromeRenderer = blockChromeRenderer
        self.focusOnAppear = focusOnAppear
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func loadView() {
        view = makeRootView()
        setupScrollView()
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        renderAndSyncSurface(makeFirstResponder: hasActiveTextInput)
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        if focusOnAppear {
            renderAndSyncSurface(makeFirstResponder: true)
        }
    }

    // MARK: - Public Actions

    public func renderAndSyncSurface(
        makeFirstResponder: Bool,
        scrollSelectionIntoView: Bool = false
    ) {
        var viewport = currentViewport()
        var nextSnapshot = session.render(in: viewport)
        setSnapshot(nextSnapshot)
        resizeCanvas(for: nextSnapshot)

        if scrollSelectionIntoView {
            scrollActiveSelectionIntoView(viewport: viewport)
            let scrolledViewport = currentViewport()
            if scrolledViewport != viewport {
                viewport = scrolledViewport
                nextSnapshot = session.render(in: viewport)
                setSnapshot(nextSnapshot)
                resizeCanvas(for: nextSnapshot)
            }
        }

        syncNativeSurface(snapshot: nextSnapshot, makeFirstResponder: makeFirstResponder)
        invalidateVisibleCanvas()
    }

    public func focus(blockID: BlockID, offset: Int) {
        handleNativeInputEvent(
            .activeTextSelectionChanged(
                blockID: blockID,
                selectedRange: .point(offset)
            )
        )
        renderAndSyncSurface(makeFirstResponder: true, scrollSelectionIntoView: true)
    }

    public func resetDocument(
        blocks: [EditorBlockInput],
        selection: EditorSelection? = nil
    ) {
        session = EditorSession(
            blocks: blocks,
            selection: selection,
            textLayouter: textLayouter
        )
        snapshot = nil
        activeInputController.hide()
    }

    @discardableResult
    public func handleInputWithoutRendering(_ inputEvent: EditorInputEvent) -> EditorUpdate? {
        handleNativeInputEvent(inputEvent)
    }

    public func replaceActiveText(
        _ text: String,
        preservingNativeSelection: Bool = false,
        blockID explicitBlockID: BlockID? = nil
    ) {
        guard
            let blockID = explicitBlockID ?? currentActiveTextBlockID(),
            snapshotText(for: blockID) != nil
        else { return }

        activeInputController.replaceText(
            text,
            blockID: blockID,
            preservingNativeSelection: preservingNativeSelection
        )
    }

    @discardableResult
    public func handleInput(
        _ inputEvent: EditorInputEvent,
        makeFirstResponder: Bool = true,
        scrollSelectionIntoView: Bool = true
    ) -> EditorUpdate? {
        guard let update = handleNativeInputEvent(inputEvent) else { return nil }
        renderAndSyncSurface(
            makeFirstResponder: makeFirstResponder,
            scrollSelectionIntoView: scrollSelectionIntoView
        )
        return update
    }

    public func renderPreservingNativeSurface() {
        renderCanvasPreservingNativeSurface()
    }

    public func scrollDocument(to y: Double) {
        scrollDocument(to: CGFloat(max(0, y)), visibleBounds: currentViewportBounds())
    }

    public func currentViewport() -> EditorViewport {
        let bounds = currentViewportBounds()
        let width = max(Double(bounds.width), Double(UX.minimumViewportDimension))
        let height = max(Double(bounds.height), Double(UX.minimumViewportDimension))
        return EditorViewport(
            width: width,
            scrollY: max(0, Double(bounds.origin.y)),
            height: height
        )
    }

    public var activeNativeText: String {
        activeInputController.activeText
    }

    public var activeNativeSelectedRange: NSRange {
        activeInputController.activeSelectedRange
    }

    public var activeNativeMarkedRange: NSRange {
        activeInputController.activeMarkedRange
    }

    public var hasActiveNativeMarkedText: Bool {
        activeInputController.hasMarkedText
    }

    public func hideActiveNativeSurface() {
        activeInputController.hide()
    }

    // MARK: - Setup

    private func makeRootView() -> NSView {
        let rootView = NSView(
            frame: NSRect(
                origin: .zero,
                size: UX.initialViewSize
            )
        )
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        return rootView
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.documentView = editorCanvasView
        view.addSubview(scrollView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewContentBoundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func scrollViewContentBoundsDidChange(_ notification: Notification) {
        guard !isAdjustingScrollPosition else { return }
        renderAndSyncSurface(makeFirstResponder: hasActiveTextInput)
    }

    private func currentViewportBounds() -> CGRect {
        var bounds = scrollView.contentView.bounds
        let fallback = view.bounds
        if bounds.width <= UX.minimumViewportDimension,
            fallback.width > UX.minimumViewportDimension
        {
            bounds.size.width = fallback.width
        }
        if bounds.height <= UX.minimumViewportDimension,
            fallback.height > UX.minimumViewportDimension
        {
            bounds.size.height = fallback.height
        }
        return bounds
    }

    private func resizeCanvas(for snapshot: EditorSessionSnapshot) {
        let bounds = currentViewportBounds()
        let documentHeight = max(
            CGFloat(snapshot.totalHeight) + UX.documentBottomPadding,
            bounds.height
        )
        editorCanvasView.setFrameSize(
            NSSize(
                width: max(UX.minimumViewportDimension, bounds.width),
                height: documentHeight
            )
        )
    }

    private func invalidateVisibleCanvas() {
        editorCanvasView.setNeedsDisplay(scrollView.contentView.bounds)
    }

    private func renderCanvasPreservingNativeSurface() {
        let nextSnapshot = session.render(in: currentViewport())
        setSnapshot(nextSnapshot)
        resizeCanvas(for: nextSnapshot)
        invalidateVisibleCanvas()
    }

    private func setSnapshot(_ nextSnapshot: EditorSessionSnapshot) {
        snapshot = nextSnapshot
        onSnapshotChanged?(nextSnapshot)
    }

    private func syncNativeSurface(snapshot: EditorSessionSnapshot, makeFirstResponder: Bool) {
        activeInputController.sync(activeTextInput: snapshot.activeTextInput)

        guard snapshot.activeTextInput != nil else { return }
        if makeFirstResponder {
            view.window?.makeFirstResponder(editorCanvasView)
        }
    }

    private func scrollActiveSelectionIntoView(viewport: EditorViewport) {
        guard
            let activePosition = activeTextPosition(),
            let frame = session.blockRevealFrame(for: activePosition.blockID, viewport: viewport)
        else { return }

        let visibleBounds = currentViewportBounds()
        let blockMinY = CGFloat(frame.y)
        let blockMaxY = CGFloat(frame.y + frame.height)
        var targetY = visibleBounds.origin.y

        if blockMaxY + UX.selectionRevealPadding > visibleBounds.maxY {
            targetY = blockMaxY + UX.selectionRevealPadding - visibleBounds.height
        }
        if blockMinY - UX.selectionRevealPadding < targetY {
            targetY = blockMinY - UX.selectionRevealPadding
        }

        let maxY = max(0, editorCanvasView.frame.height - visibleBounds.height)
        targetY = min(max(0, targetY), maxY)
        guard abs(targetY - visibleBounds.origin.y) > UX.scrollEpsilon else { return }

        scrollDocument(to: targetY, visibleBounds: visibleBounds)
    }

    private func scrollDocumentForDragAutoscroll(to targetY: CGFloat) {
        scrollDocument(to: targetY, visibleBounds: currentViewportBounds())
    }

    private func scrollDocument(to targetY: CGFloat, visibleBounds: CGRect) {
        isAdjustingScrollPosition = true
        scrollView.contentView.scroll(to: NSPoint(x: visibleBounds.origin.x, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        isAdjustingScrollPosition = false
    }
}

// MARK: - Canvas Handling

extension AppKitEditorViewController: AppKitEditorCanvasHandler {
    // MARK: - Drawing

    public func drawCanvas(_ dirtyRect: NSRect) {
        let drawStart = DispatchTime.now().uptimeNanoseconds
        defer {
            onDrawCompleted?(
                dirtyRect,
                DispatchTime.now().uptimeNanoseconds - drawStart
            )
        }

        guard let snapshot else { return }
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()

        guard let cgContext = NSGraphicsContext.current?.cgContext else { return }
        let selectedBlockIDs = selectedBlockIDs(in: snapshot)
        let activeTextBlockID = snapshot.activeTextInput?.renderDescriptor.measureRequest.blockID
        for rendered in snapshot.visibleBlocks {
            let isActive = rendered.id == activeTextBlockID
            let blockFrame = CGRect(editorRect: rendered.frame)
            do {
                cgContext.saveGState()
                defer { cgContext.restoreGState() }
                cgContext.clip(to: blockFrame)
                blockChromeRenderer.drawChrome(
                    AppKitBlockChromeRenderContext(
                        blockID: rendered.id,
                        kind: rendered.kind,
                        markerKind: rendered.markerKind,
                        depth: rendered.depth,
                        blockFrame: blockFrame,
                        style: editorStyle,
                        graphicsContext: cgContext,
                        isActive: isActive,
                        isSelected: selectedBlockIDs.contains(rendered.id)
                    )
                )
            }
        }

        for rendered in snapshot.visibleBlocks {
            textRenderer.draw(rendered.textRender, context: cgContext)
        }
        if let activeTextInput = snapshot.activeTextInput {
            textInputDecorationRenderer.draw(
                activeTextInput,
                graphicsContext: cgContext
            )
        }
        drawBlockSelectionRectangle(snapshot.blockSelectionRectangleState?.rect)
        drawDropIndicator(snapshot.blockDragState?.dropIndicator)
        onDrawOverlay?(dirtyRect, snapshot)
    }

    // MARK: - Mouse Events

    public func handleMouseDown(documentPoint: CGPoint, clickCount: Int) {
        dragAutoscrollController.stop()
        if clickCount >= 2 {
            handleMouseDoubleClick(documentPoint: documentPoint)
        } else {
            handleMouseDown(documentPoint: documentPoint)
        }
    }

    public func handleMouseDragged(documentPoint: CGPoint) {
        if snapshot?.blockDragState != nil {
            guard applyDragUpdate(kind: .blockDrag, documentPoint: documentPoint) else { return }
            dragAutoscrollController.update(kind: .blockDrag, documentPoint: documentPoint)
            return
        }

        if snapshot?.blockSelectionRectangleState != nil {
            guard applyDragUpdate(kind: .blockSelectionRectangle, documentPoint: documentPoint)
            else { return }
            dragAutoscrollController.update(
                kind: .blockSelectionRectangle,
                documentPoint: documentPoint
            )
            return
        }

        let viewport = currentViewport()
        let point = EditorPoint(x: Double(documentPoint.x), y: Double(documentPoint.y))
        if let update = session.handleInput(
            .pointer(
                .updateTextSelection(
                    documentPoint: point,
                    viewport: viewport,
                    blockSelectionThreshold: textDragBlockSelectionThreshold
                )
            )
        ) {
            onUpdate?(update)
            if case .blocks = update.selection {
                activeInputController.hide()
                renderAndSyncSurface(makeFirstResponder: false)
            } else {
                renderAndSyncSurface(makeFirstResponder: true)
            }
            return
        }

        guard case .blocks = snapshot?.selection else { return }
        guard applyDragUpdate(kind: .blockSelectionExtension, documentPoint: documentPoint)
        else { return }
        dragAutoscrollController.update(
            kind: .blockSelectionExtension,
            documentPoint: documentPoint
        )
    }

    public func handleMouseUp(documentPoint: CGPoint) {
        dragAutoscrollController.stop()
        let viewport = currentViewport()
        let point = EditorPoint(x: Double(documentPoint.x), y: Double(documentPoint.y))
        if snapshot?.blockDragState != nil {
            handleNativeInputEvent(.pointer(.endBlockDrag(documentPoint: point, viewport: viewport)))
            renderAndSyncSurface(makeFirstResponder: false)
        } else if snapshot?.blockSelectionRectangleState != nil {
            handleNativeInputEvent(.pointer(.endBlockSelectionRectangle))
            renderAndSyncSurface(makeFirstResponder: false)
        } else {
            handleNativeInputEvent(.pointer(.endTextSelection))
            handleNativeInputEvent(.pointer(.endBlockSelection))
        }
    }

    // MARK: - Native Commands

    public func handleNativeCommand(_ commandSelector: Selector) -> Bool {
        activeInputController.handleCommand(commandSelector)
    }

    // MARK: - Native Text Surface

    public func insertTextFromNativeSurface(_ text: String, replacementRange: NSRange) {
        activeInputController.insertText(text, replacementRange: replacementRange)
    }

    public func setMarkedTextFromNativeSurface(
        _ text: String,
        selectedRange: NSRange,
        replacementRange: NSRange
    ) {
        activeInputController.setMarkedText(
            text,
            selectedRange: selectedRange,
            replacementRange: replacementRange
        )
    }

    public func unmarkTextFromNativeSurface() {
        activeInputController.unmarkText()
    }

    public func nativeSelectedRange() -> NSRange {
        activeInputController.activeSelectedRange
    }

    public func nativeMarkedRange() -> NSRange {
        activeInputController.activeMarkedRange
    }

    public func hasMarkedTextForNativeSurface() -> Bool {
        activeInputController.hasMarkedText
    }

    public func attributedSubstringForNativeSurface(range: NSRange) -> NSAttributedString? {
        let text = activeInputController.activeText
        guard let swiftRange = Range(range, in: text) else { return nil }
        return NSAttributedString(string: String(text[swiftRange]))
    }

    public func firstRectForNativeSurface(range: NSRange) -> NSRect {
        guard
            let activeTextInput = snapshot?.activeTextInput,
            let caretRect = caretRect(for: activeTextInput)
        else { return .zero }
        let windowRect = editorCanvasView.convert(caretRect, to: nil)
        return view.window?.convertToScreen(windowRect) ?? windowRect
    }
}

// MARK: - Native Input Owner

extension AppKitEditorViewController: AppKitActiveInputOwner {
    func documentTextForNativeInput(blockID: BlockID) -> String? {
        snapshotText(for: blockID)
    }

    func selectedPlainTextForClipboard() -> String? {
        session.selectedPlainText()
    }

    @discardableResult
    func handleNativeInputEvent(_ inputEvent: EditorInputEvent) -> EditorUpdate? {
        guard let update = session.handleInput(inputEvent) else { return nil }
        onUpdate?(update)
        return update
    }

    func handleActiveInputRenderRequest(_ request: AppKitActiveInputRenderRequest) {
        if request.preserveNativeSurface {
            renderCanvasPreservingNativeSurface()
        } else {
            renderAndSyncSurface(
                makeFirstResponder: request.makeFirstResponder,
                scrollSelectionIntoView: request.scrollSelectionIntoView
            )
        }
    }
}

// MARK: - Pointer Handling

extension AppKitEditorViewController {
    @discardableResult
    private func applyDragUpdate(
        kind: AppKitDragAutoscrollKind,
        documentPoint: CGPoint
    ) -> Bool {
        let viewport = currentViewport()
        let point = EditorPoint(x: Double(documentPoint.x), y: Double(documentPoint.y))
        let update: EditorUpdate?

        switch kind {
        case .blockDrag:
            guard snapshot?.blockDragState != nil else { return false }
            update = handleNativeInputEvent(
                .pointer(.updateBlockDrag(documentPoint: point, viewport: viewport))
            )

        case .blockSelectionRectangle:
            guard snapshot?.blockSelectionRectangleState != nil else { return false }
            update = handleNativeInputEvent(
                .pointer(
                    .updateBlockSelectionRectangle(
                        documentPoint: point,
                        viewport: viewport
                    )
                )
            )

        case .blockSelectionExtension:
            guard case .blocks = snapshot?.selection else { return false }
            update = handleNativeInputEvent(
                .pointer(
                    .extendBlockSelection(
                        documentPoint: point,
                        region: .gutter,
                        viewport: viewport
                    )
                )
            )
        }

        if update != nil {
            activeInputController.hide()
        }
        renderAndSyncSurface(makeFirstResponder: false)
        return true
    }

    private func handleMouseDown(documentPoint: CGPoint) {
        let viewport = currentViewport()
        let point = EditorPoint(x: Double(documentPoint.x), y: Double(documentPoint.y))
        let hitRegion: BlockHitRegion = documentPoint.x < CGFloat(editorStyle.gutterWidth)
            ? .gutter
            : .body

        switch hitRegion {
        case .gutter, .dragHandle:
            if let hit = session.hitTest(
                documentPoint: point,
                region: hitRegion,
                viewport: viewport
            ),
                selectedBlockIDs().contains(hit.blockID),
                handleNativeInputEvent(
                    .pointer(.beginBlockDrag(documentPoint: point, viewport: viewport))
                ) != nil
            {
                activeInputController.hide()
                view.window?.makeFirstResponder(editorCanvasView)
                renderAndSyncSurface(makeFirstResponder: false)
                return
            }
            guard
                handleNativeInputEvent(
                    .pointer(
                        .selectBlock(
                            documentPoint: point,
                            region: hitRegion,
                            viewport: viewport
                        )
                    )
                ) != nil
            else { return }
            activeInputController.hide()

        case .body:
            if shouldBeginBlockSelectionRectangle(at: point) {
                guard
                    handleNativeInputEvent(
                        .pointer(
                            .beginBlockSelectionRectangle(
                                documentPoint: point,
                                viewport: viewport
                            )
                        )
                    ) != nil
                else { return }
                activeInputController.hide()
                view.window?.makeFirstResponder(editorCanvasView)
                renderAndSyncSurface(makeFirstResponder: false)
                return
            }

            guard
                handleNativeInputEvent(
                    .pointer(.beginTextSelection(documentPoint: point, viewport: viewport))
                ) != nil
            else { return }
        }
        view.window?.makeFirstResponder(editorCanvasView)
        renderAndSyncSurface(makeFirstResponder: hitRegion == .body)
    }

    private func handleMouseDoubleClick(documentPoint: CGPoint) {
        guard documentPoint.x >= CGFloat(editorStyle.gutterWidth) else {
            handleMouseDown(documentPoint: documentPoint)
            return
        }

        let viewport = currentViewport()
        let point = EditorPoint(x: Double(documentPoint.x), y: Double(documentPoint.y))
        guard
            handleNativeInputEvent(
                .pointer(.selectWordOrAllText(documentPoint: point, viewport: viewport))
            ) != nil
        else { return }
        view.window?.makeFirstResponder(editorCanvasView)
        renderAndSyncSurface(makeFirstResponder: true)
    }
}

// MARK: - Selection Helpers

extension AppKitEditorViewController {
    private func activeTextPosition() -> TextPosition? {
        switch snapshot?.selection {
        case .none, .inactive, .blocks:
            return nil
        case .caret(let position):
            return position
        case .text(let selection) where selection.isSingleBlock:
            return selection.focus
        case .text:
            return nil
        }
    }

    private var hasActiveTextInput: Bool {
        activeTextPosition() != nil
    }

    private var textDragBlockSelectionThreshold: Double {
        editorStyle.fontSize * editorStyle.lineHeightMultiple
    }

    private func shouldBeginBlockSelectionRectangle(at point: EditorPoint) -> Bool {
        guard point.x >= editorStyle.gutterWidth, let snapshot else { return false }
        let cgPoint = CGPoint(x: point.x, y: point.y)
        guard
            let rendered = snapshot.visibleBlocks.first(where: {
                CGRect(editorRect: $0.frame).contains(cgPoint)
            })
        else {
            return true
        }
        guard !rendered.textRender.measureRequest.text.isEmpty else { return false }

        return !textLayouter.lineFragments(for: rendered.textRender.measureRequest).contains {
            fragment in
            documentRect(fragment.rect, in: rendered.textRender)
                .insetBy(
                    dx: -UX.lineFragmentHitOutsetX,
                    dy: -UX.lineFragmentHitOutsetY
                )
                .contains(cgPoint)
        }
    }

    private func currentActiveTextBlockID() -> BlockID? {
        activeTextPosition()?.blockID
    }

    private func snapshotRenderedBlock(for blockID: BlockID) -> EditorRenderedBlock? {
        snapshot?.visibleBlocks.first { $0.id == blockID }
    }

    private func snapshotText(for blockID: BlockID) -> String? {
        if let activeTextInput = snapshot?.activeTextInput {
            let request = activeTextInput.renderDescriptor.measureRequest
            if request.blockID == blockID {
                return request.text
            }
        }
        return snapshotRenderedBlock(for: blockID)?.textRender.measureRequest.text
    }

    private func selectedBlockIDs(in snapshot: EditorSessionSnapshot) -> Set<BlockID> {
        guard case .blocks(let selection) = snapshot.selection else { return [] }
        return Set(selection.blockIDs)
    }

    private func selectedBlockIDs() -> Set<BlockID> {
        guard let snapshot else { return [] }
        return selectedBlockIDs(in: snapshot)
    }
}

// MARK: - Drawing Helpers

extension AppKitEditorViewController {
    private func drawDropIndicator(_ indicator: EditorRect?) {
        guard let indicator else { return }
        let rect = CGRect(editorRect: indicator)
        NSColor.controlAccentColor.setFill()
        rect.insetBy(dx: UX.dropIndicatorHorizontalInset, dy: 0).fill()
    }

    private func drawBlockSelectionRectangle(_ editorRect: EditorRect?) {
        guard let editorRect, editorRect.width > 0, editorRect.height > 0 else { return }
        let rect = CGRect(editorRect: editorRect)
        NSColor.selectedContentBackgroundColor.withAlphaComponent(UX.blockSelectionFillAlpha)
            .setFill()
        rect.fill()
        NSColor.selectedContentBackgroundColor.withAlphaComponent(UX.blockSelectionStrokeAlpha)
            .setStroke()
        let path = NSBezierPath(
            rect: rect.insetBy(
                dx: UX.blockSelectionStrokeInset,
                dy: UX.blockSelectionStrokeInset
            )
        )
        path.lineWidth = UX.blockSelectionStrokeWidth
        path.stroke()
    }

    private func caretRect(for descriptor: EditorSessionActiveTextInputDescriptor) -> CGRect? {
        let request = descriptor.renderDescriptor.measureRequest
        let position = TextPosition(blockID: request.blockID, offset: descriptor.focusOffset)
        guard
            let localRect = textLayouter.caretRect(
                for: position,
                in: descriptor.renderDescriptor
            )
        else { return nil }
        return documentRect(localRect, in: descriptor.renderDescriptor)
    }

    private func documentRect(
        _ localRect: EditorRect,
        in descriptor: EditorTextRenderDescriptor
    ) -> CGRect {
        let localFrame = textLayouter.textFrame(for: descriptor, measuredHeight: nil)
        return CGRect(
            x: CGFloat(localRect.x + descriptor.frame.x - localFrame.x),
            y: CGFloat(localRect.y + descriptor.frame.y - localFrame.y),
            width: CGFloat(localRect.width),
            height: CGFloat(localRect.height)
        )
    }
}
