//
//  DashboardViewModel.swift
//  uniks
//
//  Aggregates habit events into dashboard insights.
//

import Foundation
import SwiftData

/// Available date ranges for the dashboard.
enum DashboardDateRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case allTime = "All Time"

    var id: String { rawValue }

    /// The earliest date included in this range, or `nil` for all time.
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .last7Days:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .last30Days:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))
        case .allTime:
            return nil
        }
    }
}

/// A summed value for a single category.
struct CategoryTotal: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let total: Double
}

/// A summed value for a single day.
struct DailyValue: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let total: Double
}

/// A tag and how many events include it.
struct TagCount: Identifiable, Equatable {
    let id = UUID()
    let tag: String
    let count: Int
}

/// Number of events logged on a single day.
struct DailyActivity: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let count: Int
}

/// A computed insight about the user's habits.
struct HabitInsight: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let text: String
}

@MainActor
@Observable
final class DashboardViewModel {
    var selectedRange: DashboardDateRange = .last7Days {
        didSet {
            Task { await refresh() }
        }
    }

    private(set) var categoryTotals: [CategoryTotal] = []
    private(set) var dailyValues: [DailyValue] = []
    private(set) var topTags: [TagCount] = []
    private(set) var dailyActivity: [DailyActivity] = []
    private(set) var totalEvents: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var topCategory: String?
    private(set) var insights: [HabitInsight] = []

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Recomputes all dashboard aggregations from the current date range.
    func refresh() async {
        let range = selectedRange
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let events = try? context.fetch(descriptor) else {
            await MainActor.run {
                categoryTotals = []
                dailyValues = []
                topTags = []
                dailyActivity = []
            }
            return
        }

        let filtered = events.filter { event in
            guard event.state == .parsed else { return false }
            guard let startDate = range.startDate else { return true }
            return event.createdAt >= startDate
        }

        let parsed = filtered.compactMap { event -> (date: Date, payload: HabitParseResult)? in
            guard let payload = event.parsedPayload() else { return nil }
            return (event.createdAt, payload)
        }

        let calendar = Calendar.current
        let dayBuckets: [Date: [(date: Date, payload: HabitParseResult)]] = Dictionary(
            grouping: parsed,
            by: { calendar.startOfDay(for: $0.date) }
        )

        let newCategoryTotals = aggregateCategoryTotals(from: parsed)
        let newDailyValues = aggregateDailyValues(
            from: dayBuckets, calendar: calendar, range: range
        )
        let newTopTags = aggregateTopTags(from: parsed)
        let newDailyActivity = aggregateDailyActivity(
            from: dayBuckets, calendar: calendar, range: range
        )

        let newTotalEvents = filtered.count
        let newCurrentStreak = computeStreak(from: dayBuckets, calendar: calendar)
        let newTopCategory = newCategoryTotals.first?.category
        let newInsights = computeInsights(
            totalEvents: newTotalEvents,
            streak: newCurrentStreak,
            topCategory: newTopCategory,
            topTags: newTopTags
        )

        await MainActor.run {
            self.categoryTotals = newCategoryTotals
            self.dailyValues = newDailyValues
            self.topTags = newTopTags
            self.dailyActivity = newDailyActivity
            self.totalEvents = newTotalEvents
            self.currentStreak = newCurrentStreak
            self.topCategory = newTopCategory
            self.insights = newInsights
        }
    }

    private func aggregateCategoryTotals(
        from parsed: [(date: Date, payload: HabitParseResult)]
    ) -> [CategoryTotal] {
        var totals: [String: Double] = [:]
        for (_, payload) in parsed {
            let category = payload.category ?? "Uncategorized"
            totals[category, default: 0] += payload.value ?? 0
        }
        return totals
            .map { CategoryTotal(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    private func aggregateDailyValues(
        from dayBuckets: [Date: [(date: Date, payload: HabitParseResult)]],
        calendar: Calendar,
        range: DashboardDateRange
    ) -> [DailyValue] {
        let dates = sortedDays(for: range, calendar: calendar, dayBuckets: dayBuckets)
        return dates.map { date in
            let total = dayBuckets[date]?.reduce(0) { $0 + ($1.payload.value ?? 0) } ?? 0
            return DailyValue(date: date, total: total)
        }
    }

    private func aggregateTopTags(
        from parsed: [(date: Date, payload: HabitParseResult)]
    ) -> [TagCount] {
        var counts: [String: Int] = [:]
        for (_, payload) in parsed {
            for tag in payload.tags ?? [] {
                counts[tag, default: 0] += 1
            }
        }
        return counts
            .map { TagCount(tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    private func aggregateDailyActivity(
        from dayBuckets: [Date: [(date: Date, payload: HabitParseResult)]],
        calendar: Calendar,
        range: DashboardDateRange
    ) -> [DailyActivity] {
        let dates = sortedDays(for: range, calendar: calendar, dayBuckets: dayBuckets)
        return dates.map { date in
            let count = dayBuckets[date]?.count ?? 0
            return DailyActivity(date: date, count: count)
        }
    }

    private func sortedDays(
        for range: DashboardDateRange,
        calendar: Calendar,
        dayBuckets: [Date: [(date: Date, payload: HabitParseResult)]]
    ) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let startDate: Date
        switch range {
        case .today:
            startDate = today
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        case .allTime:
            return Array(dayBuckets.keys).sorted()
        }

        var dates: [Date] = []
        var current = startDate
        while current <= today {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    /// Computes the current consecutive-day logging streak ending today.
    private func computeStreak(
        from dayBuckets: [Date: [(date: Date, payload: HabitParseResult)]],
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while dayBuckets[day] != nil {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Generates simple human-readable insights.
    private func computeInsights(
        totalEvents: Int,
        streak: Int,
        topCategory: String?,
        topTags: [TagCount]
    ) -> [HabitInsight] {
        var results: [HabitInsight] = []
        if streak >= 3 {
            results.append(HabitInsight(
                icon: "flame.fill",
                text: "You're on a \(streak)-day streak! Keep it up."
            ))
        }
        if let top = topCategory {
            results.append(HabitInsight(
                icon: "star.fill",
                text: "Your most-logged category is \(top)."
            ))
        }
        if let tag = topTags.first, tag.count >= 3 {
            results.append(HabitInsight(
                icon: "tag.fill",
                text: "#\(tag.tag) appears in \(tag.count) events."
            ))
        }
        return results
    }
}
