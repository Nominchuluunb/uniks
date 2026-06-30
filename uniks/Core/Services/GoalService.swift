//
//  GoalService.swift
//  uniks
//
//  Computes progress for user-defined goals against logged events.
//

import Foundation
import SwiftData

/// Sendable snapshot of Goal data.
struct GoalSnapshot: Identifiable, Sendable {
    let id: UUID
    let category: String
    let targetCount: Int
    let frequency: GoalFrequency
    let emoji: String
    let isActive: Bool

    var goalFrequency: GoalFrequency { frequency }
}

/// Progress snapshot for a single goal.
struct GoalProgress: Identifiable, Sendable {
    let id: UUID
    let goal: GoalSnapshot
    let currentCount: Int
    var fractionCompleted: Double {
        guard goal.targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(goal.targetCount), 1.0)
    }
    var isCompleted: Bool { currentCount >= goal.targetCount }
    var remaining: Int { max(goal.targetCount - currentCount, 0) }
}

/// Computes goal progress by querying events in the current period.
actor GoalService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Fetches all active goals with their current progress.
    func allProgress() async throws -> [GoalProgress] {
        let context = ModelContext(container)
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isActive == true }
        )
        let goals = try context.fetch(goalDescriptor)

        let eventDescriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let events = try context.fetch(eventDescriptor)

        let calendar = Calendar.current
        let now = Date()

        var results: [GoalProgress] = []
        for goal in goals {
            let periodStart = periodStartDate(for: goal.goalFrequency, now: now, calendar: calendar)
            var count = 0
            for event in events {
                guard event.state == .parsed || event.state == .heuristicParsed || event.state == .enriched,
                      event.createdAt >= periodStart,
                      let payload = event.parsedPayload(),
                      let cat = payload.category?.lowercased(),
                      cat == goal.category.lowercased() else { continue }
                count += 1
            }
            let snapshot = GoalSnapshot(
                id: goal.id,
                category: goal.category,
                targetCount: goal.targetCount,
                frequency: goal.goalFrequency,
                emoji: goal.emoji,
                isActive: goal.isActive
            )
            results.append(GoalProgress(id: goal.id, goal: snapshot, currentCount: count))
        }
        return results
    }

    private func periodStartDate(for frequency: GoalFrequency, now: Date, calendar: Calendar) -> Date {
        switch frequency {
        case .daily:
            return calendar.startOfDay(for: now)
        case .weekly:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .monthly:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) ?? now
        }
    }
}
