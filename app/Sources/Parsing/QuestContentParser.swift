// QuestContentParser.swift — Parses a quest content.md string into typed ContentBlocks.
import Foundation

struct QuestContentParser {

    enum ParseError: Error {
        case malformedCheckpoint(String)
    }

    func parse(_ markdown: String) throws -> [ContentBlock] {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var blocks: [ContentBlock] = []
        var pendingText: [String] = []
        var lines = markdown.components(separatedBy: "\n").makeIterator()

        func flushText() {
            let joined = pendingText.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.text(joined))
            }
            pendingText = []
        }

        while let line = lines.next() {
            if line.hasPrefix("~~~checkpoint") {
                flushText()
                // Read until closing ~~~
                var id = ""
                var label = ""
                while let inner = lines.next() {
                    if inner.hasPrefix("~~~") { break }
                    if inner.hasPrefix("id: ") { id = String(inner.dropFirst(4)) }
                    if inner.hasPrefix("label: ") { label = String(inner.dropFirst(7)) }
                }
                blocks.append(.checkpoint(id: id, label: label))
            } else if line.hasPrefix("![](") && line.hasSuffix(")") {
                flushText()
                let filename = String(line.dropFirst(4).dropLast(1))
                blocks.append(.image(filename))
            } else {
                pendingText.append(line)
            }
        }
        flushText()
        return blocks
    }
}
