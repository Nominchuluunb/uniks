//
//  Goal.swift
//  uniks
//
//  User-defined habit goals with progress tracking.
//

import Foundation
import SwiftData

/// Frequency at which a goal is measured.
enum GoalFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    /// Number of days in this frequency period.
    var periodDays: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        }
    }
}

/// A user-defined habit goal (e.g., "Run 3x/week").
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var category: String
    var targetCount: Int
    var frequency: String // GoalFrequency raw value
    var emoji: String
    var createdAt: Date
    var isActive: Bool

    init(
        category: String,
        targetCount: Int,
        frequency: GoalFrequency,
        emoji: String = "🎯"
    ) {
        self.id = UUID()
        self.category = category
        self.targetCount = targetCount
        self.frequency = frequency.rawValue
        self.emoji = emoji
        self.createdAt = Date()
        self.isActive = true
    }

    var goalFrequency: GoalFrequency {
        GoalFrequency(rawValue: frequency) ?? .weekly
    }
}
