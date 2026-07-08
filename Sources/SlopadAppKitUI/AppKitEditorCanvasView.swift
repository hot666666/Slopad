import AppKit

// MARK: - AppKitEditorCanvasHandler

@MainActor
public protocol AppKitEditorCanvasHandler: AnyObject {
    func drawCanvas(_ dirtyRect: NSRect)
    func handleMouseDown(documentPoint: CGPoint, clickCount: Int)
    func handleMouseDragged(documentPoint: CGPoint)
    func handleMouseUp(documentPoint: CGPoint)
    func handleNativeCommand(_ commandSelector: Selector) -> Bool
    func insertTextFromNativeSurface(_ text: String, replacementRange: NSRange)
    func setMarkedTextFromNativeSurface(
        _ text: String,
        selectedRange: NSRange,
        replacementRange: NSRange
    )
    func unmarkTextFromNativeSurface()
    func nativeSelectedRange() -> NSRange
    func nativeMarkedRange() -> NSRange
    func hasMarkedTextForNativeSurface() -> Bool
    func attributedSubstringForNativeSurface(range: NSRange) -> NSAttributedString?
    func firstRectForNativeSurface(range: NSRange) -> NSRect
}

// MARK: - AppKitEditorCanvasView

@MainActor
public final class AppKitEditorCanvasView: NSView, @preconcurrency NSTextInputClient {
    // MARK: - Private Types

    private enum Accessibility {
        static let canvasIdentifier = "AppKitEditorCanvas"
    }

    // MARK: - Public State

    public weak var handler: (any AppKitEditorCanvasHandler)?

    // MARK: - Init

    public init(
        handler: (any AppKitEditorCanvasHandler)? = nil,
        frame: NSRect = NSRect(x: 0, y: 0, width: 860, height: 900)
    ) {
        self.handler = handler
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - NSView

    public override var isFlipped: Bool {
        true
    }

    public override var isOpaque: Bool {
        true
    }

    public override var acceptsFirstResponder: Bool {
        true
    }

    public override func draw(_ dirtyRect: NSRect) {
        handler?.drawCanvas(dirtyRect)
    }

    public override func mouseDown(with event: NSEvent) {
        handler?.handleMouseDown(
            documentPoint: convert(event.locationInWindow, from: nil),
            clickCount: event.clickCount
        )
    }

    public override func mouseDragged(with event: NSEvent) {
        handler?.handleMouseDragged(documentPoint: convert(event.locationInWindow, from: nil))
    }

    public override func mouseUp(with event: NSEvent) {
        handler?.handleMouseUp(documentPoint: convert(event.locationInWindow, from: nil))
    }

    // MARK: - Keyboard

    public override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let actionModifiers = modifiers.intersection([.command, .control, .option, .shift])
        if let commandSelector = AppKitKeyboardCommandMapper.commandSelector(
            for: event,
            modifiers: actionModifiers
        ) {
            _ = handler?.handleNativeCommand(commandSelector)
            return
        }

        if AppKitKeyboardCommandMapper.isReturnKey(event), modifiers.contains(.shift) {
            _ = handler?.handleNativeCommand(AppKitCommandSelectors.insertLineBreak)
            return
        }

        let tabSystemModifiers = modifiers.intersection([.command, .control, .option])
        if AppKitKeyboardCommandMapper.isTabKey(event), tabSystemModifiers.isEmpty {
            if modifiers.contains(.shift) {
                _ = handler?.handleNativeCommand(AppKitCommandSelectors.insertBacktab)
            } else {
                _ = handler?.handleNativeCommand(AppKitCommandSelectors.insertTab)
            }
            return
        }

        interpretKeyEvents([event])
    }

    public override func doCommand(by selector: Selector) {
        if handler?.handleNativeCommand(selector) == true {
            return
        }
        super.doCommand(by: selector)
    }

    // MARK: - NSTextInputClient

    public func insertText(_ string: Any, replacementRange: NSRange) {
        guard let text = Self.plainText(from: string) else { return }
        handler?.insertTextFromNativeSurface(text, replacementRange: replacementRange)
    }

    public func setMarkedText(
        _ string: Any,
        selectedRange: NSRange,
        replacementRange: NSRange
    ) {
        guard let text = Self.plainText(from: string) else { return }
        handler?.setMarkedTextFromNativeSurface(
            text,
            selectedRange: selectedRange,
            replacementRange: replacementRange
        )
    }

    public func unmarkText() {
        handler?.unmarkTextFromNativeSurface()
    }

    public func selectedRange() -> NSRange {
        handler?.nativeSelectedRange() ?? NSRange(location: 0, length: 0)
    }

    public func markedRange() -> NSRange {
        handler?.nativeMarkedRange() ?? NSRange(location: NSNotFound, length: 0)
    }

    public func hasMarkedText() -> Bool {
        handler?.hasMarkedTextForNativeSurface() ?? false
    }

    public func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        actualRange?.pointee = range
        return handler?.attributedSubstringForNativeSurface(range: range)
    }

    public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [.foregroundColor, .backgroundColor, .underlineStyle]
    }

    public func firstRect(
        forCharacterRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSRect {
        actualRange?.pointee = range
        return handler?.firstRectForNativeSurface(range: range) ?? .zero
    }

    public func characterIndex(for point: NSPoint) -> Int {
        selectedRange().location
    }

    // MARK: - Helpers

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        setAccessibilityIdentifier(Accessibility.canvasIdentifier)
    }

    private static func plainText(from string: Any) -> String? {
        if let string = string as? String {
            return string
        }
        if let attributedString = string as? NSAttributedString {
            return attributedString.string
        }
        return nil
    }
}
