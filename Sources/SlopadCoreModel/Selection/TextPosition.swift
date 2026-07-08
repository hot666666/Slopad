// MARK: - TextPosition

public struct TextPosition: Hashable, Codable, Sendable {
    public var blockID: BlockID
    public var offset: Int

    public init(blockID: BlockID, offset: Int) {
        self.blockID = blockID
        self.offset = offset
    }
}
