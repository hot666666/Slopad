// MARK: - DocumentInvariantViolation

enum DocumentInvariantViolation: Hashable, Sendable {
    case invalidRootParent(BlockID, actualParent: BlockID?)
    case missingBlockReference(parent: BlockID?, child: BlockID)
    case duplicateChild(parent: BlockID?, child: BlockID)
    case parentChildMismatch(parent: BlockID?, child: BlockID, actualParent: BlockID?)
    case orphan(BlockID)
    case cycleDetected(BlockID)
    case visibleSequenceMismatch(expected: [BlockID], actual: [BlockID])
}

// MARK: - DocumentInvariantReport

struct DocumentInvariantReport: Hashable, Sendable {
    var violations: [DocumentInvariantViolation]

    init(violations: [DocumentInvariantViolation]) {
        self.violations = violations
    }

    var isValid: Bool {
        violations.isEmpty
    }
}

// MARK: - Document Invariants

extension Document {
    func validateInvariants() -> DocumentInvariantReport {
        let document = self
        var violations: [DocumentInvariantViolation] = []
        var seenEdges: Set<String> = []
        var visited: Set<BlockID> = []
        var visiting: Set<BlockID> = []

        func visit(_ blockID: BlockID, parentID: BlockID?) {
            let key = "\(parentID?.rawValue ?? "root")->\(blockID.rawValue)"
            if seenEdges.contains(key) {
                violations.append(.duplicateChild(parent: parentID, child: blockID))
                return
            }
            seenEdges.insert(key)

            guard let block = document.blocks[blockID] else {
                violations.append(.missingBlockReference(parent: parentID, child: blockID))
                return
            }
            if visiting.contains(blockID) {
                violations.append(.cycleDetected(blockID))
                return
            }
            if visited.contains(blockID) {
                violations.append(.duplicateChild(parent: parentID, child: blockID))
                return
            }

            if block.parentID != parentID {
                if parentID == nil {
                    violations.append(.invalidRootParent(blockID, actualParent: block.parentID))
                } else {
                    violations.append(
                        .parentChildMismatch(
                            parent: parentID, child: blockID, actualParent: block.parentID))
                }
            }

            visiting.insert(blockID)
            for childID in block.childIDs {
                visit(childID, parentID: blockID)
            }
            visiting.remove(blockID)
            visited.insert(blockID)
        }

        for rootID in document.rootBlockIDs {
            visit(rootID, parentID: nil)
        }

        for blockID in document.blocks.keys where !visited.contains(blockID) {
            violations.append(.orphan(blockID))
        }

        let visible = Self.uniqueReferencedPreorder(document)
        let rawPreorder = Self.rawReferencedPreorder(document)
        if visible != rawPreorder {
            violations.append(.visibleSequenceMismatch(expected: rawPreorder, actual: visible))
        }

        return DocumentInvariantReport(violations: violations)
    }

    package func assertValidInvariants(file: StaticString = #fileID, line: UInt = #line) {
        let report = validateInvariants()
        precondition(
            report.isValid,
            "Invalid document invariants: \(report.violations)",
            file: file,
            line: line
        )
    }

    private static func rawReferencedPreorder(_ document: Document) -> [BlockID] {
        var output: [BlockID] = []
        let limit = max(1, document.blocks.count * 2 + document.rootBlockIDs.count + 1)

        func visit(_ blockID: BlockID) {
            guard output.count < limit else { return }
            output.append(blockID)
            guard let block = document.blocks[blockID] else { return }
            for childID in block.childIDs {
                visit(childID)
            }
        }

        for rootID in document.rootBlockIDs {
            visit(rootID)
        }
        return output
    }

    private static func uniqueReferencedPreorder(_ document: Document) -> [BlockID] {
        var output: [BlockID] = []
        var visited: Set<BlockID> = []

        func visit(_ blockID: BlockID) {
            guard visited.insert(blockID).inserted else { return }
            output.append(blockID)
            guard let block = document.blocks[blockID] else { return }
            for childID in block.childIDs {
                visit(childID)
            }
        }

        for rootID in document.rootBlockIDs {
            visit(rootID)
        }
        return output
    }
}
