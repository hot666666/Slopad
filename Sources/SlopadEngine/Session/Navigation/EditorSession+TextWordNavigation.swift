import SlopadCoreModel

// MARK: - Text Word Navigation

extension EditorSession {
    func spaceDelimitedWordRange(in text: String, containing offset: Int) -> TextRange {
        guard !text.isEmpty else { return .point(0) }

        var index = clampedTextOffset(offset, in: text)
        if index == text.count {
            index -= 1
        }
        if character(at: index, in: text) == " " {
            if index > 0, character(at: index - 1, in: text) != " " {
                index -= 1
            } else {
                while index < text.count, character(at: index, in: text) == " " {
                    index += 1
                }
                guard index < text.count else {
                    return .point(clampedTextOffset(offset, in: text))
                }
            }
        }

        var lowerBound = index
        while lowerBound > 0, character(at: lowerBound - 1, in: text) != " " {
            lowerBound -= 1
        }

        var upperBound = index
        while upperBound < text.count, character(at: upperBound, in: text) != " " {
            upperBound += 1
        }

        return TextRange(lowerBound, upperBound)
    }

    func previousSpaceDelimitedWordBoundary(in text: String, from offset: Int) -> Int {
        var index = clampedTextOffset(offset, in: text)
        while index > 0, character(at: index - 1, in: text) == " " {
            index -= 1
        }
        while index > 0, character(at: index - 1, in: text) != " " {
            index -= 1
        }
        return index
    }

    func nextSpaceDelimitedWordBoundary(in text: String, from offset: Int) -> Int {
        var index = clampedTextOffset(offset, in: text)
        while index < text.count, character(at: index, in: text) == " " {
            index += 1
        }
        while index < text.count, character(at: index, in: text) != " " {
            index += 1
        }
        return index
    }

    private func clampedTextOffset(_ offset: Int, in text: String) -> Int {
        max(0, min(offset, text.count))
    }

    private func character(at offset: Int, in text: String) -> Character {
        let index = text.indexAtGraphemeOffset(offset)
        return text[index]
    }
}
