// QuestContentParserTests.swift — Unit tests for QuestContentParser.
import XCTest
@testable import TOTKWalkthrough

final class QuestContentParserTests: XCTestCase {

    private let markdown = """
    Head north from Lookout Landing.

    Watch out for Gloom Hands.

    ![](image-001.png)

    Enter the underground passage.

    ~~~checkpoint
    id: reached-the-gates
    label: Reached the castle gates?
    ~~~

    Continue north.
    """

    func test_parse_producesTextBlock() throws {
        let blocks = try QuestContentParser().parse(markdown)
        let texts = blocks.compactMap { if case .text(let s) = $0 { return s } else { return nil } }
        XCTAssertTrue(texts.contains(where: { $0.contains("Head north") }))
    }

    func test_parse_producesImageBlock() throws {
        let blocks = try QuestContentParser().parse(markdown)
        let images = blocks.compactMap { if case .image(let f) = $0 { return f } else { return nil } }
        XCTAssertEqual(images, ["image-001.png"])
    }

    func test_parse_producesCheckpointBlock() throws {
        let blocks = try QuestContentParser().parse(markdown)
        let checkpoints = blocks.compactMap { block -> (String, String)? in
            if case .checkpoint(let id, let label) = block { return (id, label) }
            return nil
        }
        XCTAssertEqual(checkpoints.count, 1)
        XCTAssertEqual(checkpoints[0].0, "reached-the-gates")
        XCTAssertEqual(checkpoints[0].1, "Reached the castle gates?")
    }

    func test_parse_orderIsPreserved() throws {
        let blocks = try QuestContentParser().parse(markdown)
        var sawImage = false
        var textAfterImage = false
        for block in blocks {
            switch block {
            case .image: sawImage = true
            case .text(let s) where sawImage && s.contains("Enter the underground"):
                textAfterImage = true
            default: break
            }
        }
        XCTAssertTrue(textAfterImage, "Text block after image should appear in order")
    }

    func test_parse_emptyStringProducesNoBlocks() throws {
        let blocks = try QuestContentParser().parse("")
        XCTAssertTrue(blocks.isEmpty)
    }
}
