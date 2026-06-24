//
//  Icons.swift
//  uniks
//
//  Centralized SF Symbol names. Views must not use raw symbol strings.
//

import Foundation

enum Icons {
    static let add = "plus"
    static let events = "list.bullet"
    static let dashboard = "chart.bar"
    static let settings = "gear"
    static let success = "checkmark.circle.fill"
    static let failure = "exclamationmark.circle.fill"
    static let pending = "sparkles"
    static let category = "folder"
    static let value = "number"
    static let tag = "tag"
    static let notes = "text.alignleft"
    static let chart = "chart.bar"
    static let emptyEvents = "text.badge.plus"
    static let emptyDashboard = "chart.bar"
    static let checkmark = "checkmark"
    static let bolt = "bolt.fill"
    static let gear = "gearshape.fill"
    static let engine = "cpu"
    static let model = "square.3.layers.3d"
    static let privacy = "lock.shield"
    static let sparkles = "sparkles"
    static let sparkle = "sparkle"
    static let chevronLeft = "chevron.left"
    static let pencil = "pencil"
    static let plus = "plus"
    static let trayAndArrowDown = "tray.and.arrow.down.fill"
    static let trash = "trash"
    static let retry = "arrow.clockwise"
    static let inspector = "doc.text.magnifyingglass"

    /// Returns the SF Symbol name for a given category name.
    static func categorySymbol(for categoryName: String?) -> String {
        guard let name = categoryName?.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "folder.fill"
        }

        switch name {
        case "fitness", "sport", "workout", "exercise", "run", "gym":
            return "dumbbell.fill"
        case "health", "medical", "symptom", "medicine", "pill":
            return "heart.fill"
        case "sleep":
            return "bed.double.fill"
        case "reading", "study", "learning", "education", "book":
            return "book.fill"
        case "work", "productivity":
            return "doc.text.fill"
        case "vehicle", "car", "fuel", "drive", "travel", "transport":
            return "car.fill"
        case "finance", "money", "spent", "cost", "income", "buy":
            return "creditcard.fill"
        case "diet", "food", "nutrition", "water", "drink", "meal":
            return "fork.knife"
        default:
            return "tag.fill"
        }
    }
}
