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
