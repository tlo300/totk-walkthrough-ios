// ContentBlock.swift — Typed content block produced by QuestContentParser.
import Foundation

enum ContentBlock {
    /// A run of Markdown text rendered as an AttributedString.
    case text(String)
    /// An image filename relative to the quest's content folder.
    case image(String)
    /// A progress checkpoint with a unique id and display label.
    case checkpoint(id: String, label: String)
}
