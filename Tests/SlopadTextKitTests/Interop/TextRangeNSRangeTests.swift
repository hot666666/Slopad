import Foundation
import Testing

@testable import SlopadEngine
@testable import SlopadTextKit

@Suite("TextRange와 NSRange 변환")
struct TextRangeNSRangeTests {
    @Test("UTF-16 범위 변환은 이모지 grapheme 경계를 보존한다")
    func emojiRangeRoundTripsThroughUTF16() {
        // Given
        let text = "a\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}b"
        let emojiRange = TextRange(1, 2)

        // When
        let nsRange = emojiRange.textKitNSRange(in: text)
        let roundTripped = nsRange.slopadTextRange(in: text)
        let splitUTF16Offset = NSRange(location: nsRange.location + 1, length: 0)

        // Then
        #expect(nsRange.location == 1)
        #expect(nsRange.length > emojiRange.length)
        #expect(roundTripped == emojiRange)
        #expect(splitUTF16Offset.slopadTextRange(in: text) == nil)
    }
}
