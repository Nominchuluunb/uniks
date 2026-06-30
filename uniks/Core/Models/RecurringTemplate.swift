//
//  RecurringTemplate.swift
//  uniks
//
//  User-defined recurring event templates with notification scheduling.
//

import Foundation
import SwiftData

/// A user-defined recurring template that can trigger notifications.
@Model
final class RecurringTemplate {
    @Attribute(.unique) var id: UUID
    var phrase: String
    var emoji: String
    var category: String
    var frequencyRaw: String
    var hour: Int
    var minute: Int
    var isActive: Bool
    var notificationEnabled: Bool
    var createdAt: Date

    init(
        phrase: String,
        emoji: String = "⚡",
        category: String = "",
        frequency: TemplateFrequency = .daily,
        hour: Int = 9,
        minute: Int = 0,
        notificationEnabled: Bool = true
    ) {
        self.id = UUID()
        self.phrase = phrase
        self.emoji = emoji
        self.category = category
        self.frequencyRaw = frequency.rawValue
        self.hour = hour
        self.minute = minute
        self.isActive = true
        self.notificationEnabled = notificationEnabled
        self.createdAt = Date()
    }

    var frequency: TemplateFrequency {
        get { TemplateFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    /// A `Sendable` value snapshot safe to pass across actor boundaries.
    var snapshot: RecurringTemplateSnapshot {
        RecurringTemplateSnapshot(
            id: id,
            phrase: phrase,
            emoji: emoji,
            frequency: frequency,
            hour: hour,
            minute: minute,
            isActive: isActive,
            notificationEnabled: notificationEnabled
        )
    }
}

/// An immutable, `Sendable` snapshot of a `RecurringTemplate` for use across
/// actor boundaries (e.g. when scheduling notifications). SwiftData `@Model`
/// types are not `Sendable`, so the live model must not cross isolation domains.
struct RecurringTemplateSnapshot: Sendable {
    let id: UUID
    let phrase: String
    let emoji: String
    let frequency: TemplateFrequency
    let hour: Int
    let minute: Int
    let isActive: Bool
    let notificationEnabled: Bool
}

/// Frequency options for recurring templates.
enum TemplateFrequency: String, Codable, Sendable, CaseIterable {
    case hourly
    case daily
    case weekly

    var displayName: String {
        switch self {
        case .hourly: return "Every few hours"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}
