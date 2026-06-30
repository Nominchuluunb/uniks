//
//  CustomCategory.swift
//  uniks
//
//  User-defined custom categories with keywords for heuristic parsing.
//

import Foundation
import SwiftData

/// A user-defined category that takes priority in heuristic parsing.
@Model
final class CustomCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var keywords: String // Comma-separated keywords
    var colorIndex: Int
    var sortOrder: Int
    var createdAt: Date

    init(name: String, keywords: [String] = [], colorIndex: Int = 0, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.keywords = keywords.joined(separator: ",")
        self.colorIndex = colorIndex
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    /// Parsed keywords array.
    var keywordList: [String] {
        get {
            keywords.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set {
            keywords = newValue.joined(separator: ",")
        }
    }
}
