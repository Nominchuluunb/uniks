//
//  GoalService.swift
//  uniks
//
//  Computes progress for user-defined goals against logged events.
//

import Foundation
import SwiftData

/// Progress snapshot for a single goal.
struct GoalProgress: Identifiable, Sendable {
    let id: UUID
    let goal: Goal
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

        return goals.map { goal in
            let periodStart = periodStartDate(for: goal.goalFrequency, now: now, calendar: calendar)
            let count = events.filter { event in
                guard event.state == .parsed,
                      event.createdAt >= periodStart,
                      let payload = event.parsedPayload(),
                      let cat = payload.category?.lowercased() else { return false }
                return cat == goal.category.lowercased()
            }.count
            return GoalProgress(id: goal.id, goal: goal, currentCount: count)
        }
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
