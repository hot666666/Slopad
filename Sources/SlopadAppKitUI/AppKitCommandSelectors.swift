import AppKit

// MARK: - AppKitCommandSelectors

public enum AppKitCommandSelectors {
    public static let insertNewline = #selector(NSResponder.insertNewline(_:))
    public static let insertLineBreak = #selector(NSResponder.insertLineBreak(_:))
    public static let insertNewlineIgnoringFieldEditor =
        #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:))
    public static let insertTab = #selector(NSResponder.insertTab(_:))
    public static let insertBacktab = #selector(NSResponder.insertBacktab(_:))
    public static let deleteBackward = #selector(NSResponder.deleteBackward(_:))
    public static let deleteForward = #selector(NSResponder.deleteForward(_:))
    public static let deleteToBeginningOfLine = #selector(NSResponder.deleteToBeginningOfLine(_:))
    public static let deleteWordBackward = #selector(NSResponder.deleteWordBackward(_:))
    public static let moveUp = #selector(NSResponder.moveUp(_:))
    public static let moveDown = #selector(NSResponder.moveDown(_:))
    public static let moveLeft = #selector(NSResponder.moveLeft(_:))
    public static let moveRight = #selector(NSResponder.moveRight(_:))
    public static let moveToBeginningOfLine = #selector(NSResponder.moveToBeginningOfLine(_:))
    public static let moveToEndOfLine = #selector(NSResponder.moveToEndOfLine(_:))
    public static let moveToBeginningOfLineAndModifySelection =
        #selector(NSResponder.moveToBeginningOfLineAndModifySelection(_:))
    public static let moveToEndOfLineAndModifySelection =
        #selector(NSResponder.moveToEndOfLineAndModifySelection(_:))
    public static let moveWordLeft = #selector(NSResponder.moveWordLeft(_:))
    public static let moveWordRight = #selector(NSResponder.moveWordRight(_:))
    public static let moveWordLeftAndModifySelection =
        #selector(NSResponder.moveWordLeftAndModifySelection(_:))
    public static let moveWordRightAndModifySelection =
        #selector(NSResponder.moveWordRightAndModifySelection(_:))
    public static let moveLeftAndModifySelection =
        #selector(NSResponder.moveLeftAndModifySelection(_:))
    public static let moveRightAndModifySelection =
        #selector(NSResponder.moveRightAndModifySelection(_:))
    public static let moveUpAndModifySelection = #selector(NSResponder.moveUpAndModifySelection(_:))
    public static let moveDownAndModifySelection =
        #selector(NSResponder.moveDownAndModifySelection(_:))
    public static let cancelOperation = #selector(NSResponder.cancelOperation(_:))
    public static let selectAll = #selector(NSResponder.selectAll(_:))
    public static let copy = NSSelectorFromString("copy:")
    public static let cut = NSSelectorFromString("cut:")
    public static let paste = NSSelectorFromString("paste:")
    public static let undo = NSSelectorFromString("undo:")
    public static let redo = NSSelectorFromString("redo:")
}

// MARK: - AppKitKeyCode

enum AppKitKeyCode {
    static let a: UInt16 = 0
    static let z: UInt16 = 6
    static let x: UInt16 = 7
    static let c: UInt16 = 8
    static let v: UInt16 = 9
    static let `return`: UInt16 = 36
    static let tab: UInt16 = 48
    static let delete: UInt16 = 51
    static let keypadEnter: UInt16 = 76
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let downArrow: UInt16 = 125
    static let upArrow: UInt16 = 126
}

// MARK: - Keyboard Mapping

enum AppKitKeyboardCommandMapper {
    static func commandSelector(
        for event: NSEvent,
        modifiers: NSEvent.ModifierFlags
    ) -> Selector? {
        if isAKey(event), modifiers == .command {
            return AppKitCommandSelectors.selectAll
        }
        if isCKey(event), modifiers == .command {
            return AppKitCommandSelectors.copy
        }
        if isXKey(event), modifiers == .command {
            return AppKitCommandSelectors.cut
        }
        if isVKey(event), modifiers == .command {
            return AppKitCommandSelectors.paste
        }
        if isZKey(event), modifiers == .command {
            return AppKitCommandSelectors.undo
        }
        if isZKey(event), modifiers == [.command, .shift] {
            return AppKitCommandSelectors.redo
        }

        switch (event.keyCode, modifiers) {
        case (AppKitKeyCode.leftArrow, [.command, .shift]):
            return AppKitCommandSelectors.moveToBeginningOfLineAndModifySelection
        case (AppKitKeyCode.rightArrow, [.command, .shift]):
            return AppKitCommandSelectors.moveToEndOfLineAndModifySelection
        case (AppKitKeyCode.leftArrow, [.option, .shift]):
            return AppKitCommandSelectors.moveWordLeftAndModifySelection
        case (AppKitKeyCode.rightArrow, [.option, .shift]):
            return AppKitCommandSelectors.moveWordRightAndModifySelection
        case (AppKitKeyCode.leftArrow, .command):
            return AppKitCommandSelectors.moveToBeginningOfLine
        case (AppKitKeyCode.rightArrow, .command):
            return AppKitCommandSelectors.moveToEndOfLine
        case (AppKitKeyCode.leftArrow, .option):
            return AppKitCommandSelectors.moveWordLeft
        case (AppKitKeyCode.rightArrow, .option):
            return AppKitCommandSelectors.moveWordRight
        case (AppKitKeyCode.delete, .command):
            return AppKitCommandSelectors.deleteToBeginningOfLine
        case (AppKitKeyCode.delete, .option):
            return AppKitCommandSelectors.deleteWordBackward
        case (AppKitKeyCode.leftArrow, .shift):
            return AppKitCommandSelectors.moveLeftAndModifySelection
        case (AppKitKeyCode.rightArrow, .shift):
            return AppKitCommandSelectors.moveRightAndModifySelection
        case (AppKitKeyCode.upArrow, .shift):
            return AppKitCommandSelectors.moveUpAndModifySelection
        case (AppKitKeyCode.downArrow, .shift):
            return AppKitCommandSelectors.moveDownAndModifySelection
        default:
            return nil
        }
    }

    static func isReturnKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.return
            || event.keyCode == AppKitKeyCode.keypadEnter
    }

    static func isTabKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.tab
    }

    private static func isAKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.a
            || event.charactersIgnoringModifiers?.lowercased() == "a"
    }

    private static func isCKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.c
            || event.charactersIgnoringModifiers?.lowercased() == "c"
    }

    private static func isVKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.v
            || event.charactersIgnoringModifiers?.lowercased() == "v"
    }

    private static func isXKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.x
            || event.charactersIgnoringModifiers?.lowercased() == "x"
    }

    private static func isZKey(_ event: NSEvent) -> Bool {
        event.keyCode == AppKitKeyCode.z
            || event.charactersIgnoringModifiers?.lowercased() == "z"
    }
}
