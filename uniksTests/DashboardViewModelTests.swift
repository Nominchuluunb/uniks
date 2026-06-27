//
//  DashboardViewModelTests.swift
//  uniksTests
//
//  Unit tests for dashboard aggregation logic.
//

import Foundation
import SwiftData
import Testing
@testable import uniks

@MainActor
struct DashboardViewModelTests {

    @Test func aggregatesCategoryTotals() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "Ran 5km",
            payload: HabitParseResult(category: "fitness", value: 5, unit: "km"),
            createdAt: Date()
        )
        insertEvent(
            container: container,
            rawInput: "Ran 3km",
            payload: HabitParseResult(category: "fitness", value: 3, unit: "km"),
            createdAt: Date()
        )
        insertEvent(
            container: container,
            rawInput: "Read 30 pages",
            payload: HabitParseResult(category: "reading", value: 30, unit: "pages"),
            createdAt: Date()
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        let totals = viewModel.categoryTotals
        #expect(totals.count == 2)
        #expect(totals.first { $0.category == "fitness" }?.total == 8)
        #expect(totals.first { $0.category == "reading" }?.total == 30)
    }

    @Test func aggregatesDailyValues() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))

        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "Ran 5km",
            payload: HabitParseResult(category: "fitness", value: 5, unit: "km"),
            createdAt: today
        )
        insertEvent(
            container: container,
            rawInput: "Ran 3km",
            payload: HabitParseResult(category: "fitness", value: 3, unit: "km"),
            createdAt: yesterday
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .last7Days
        await viewModel.refresh()

        let values = viewModel.dailyValues
        #expect(values.count == 7)
        #expect(values.first { calendar.isDate($0.date, inSameDayAs: today) }?.total == 5)
        #expect(values.first { calendar.isDate($0.date, inSameDayAs: yesterday) }?.total == 3)
    }

    @Test func aggregatesTopTags() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "Morning run",
            payload: HabitParseResult(category: "fitness", value: 5, tags: ["run", "morning"]),
            createdAt: Date()
        )
        insertEvent(
            container: container,
            rawInput: "Evening run",
            payload: HabitParseResult(category: "fitness", value: 5, tags: ["run", "evening"]),
            createdAt: Date()
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        let tags = viewModel.topTags
        #expect(tags.first { $0.tag == "run" }?.count == 2)
        #expect(tags.first { $0.tag == "morning" }?.count == 1)
        #expect(tags.first { $0.tag == "evening" }?.count == 1)
    }

    @Test func aggregatesDailyActivity() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "A",
            payload: HabitParseResult(category: "a", value: 1),
            createdAt: today
        )
        insertEvent(
            container: container,
            rawInput: "B",
            payload: HabitParseResult(category: "b", value: 2),
            createdAt: today
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .today
        await viewModel.refresh()

        let activity = viewModel.dailyActivity
        #expect(activity.count == 1)
        #expect(activity.first?.count == 2)
    }

    @Test func filtersByDateRange() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fortyDaysAgo = try #require(calendar.date(byAdding: .day, value: -40, to: today))

        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "Recent",
            payload: HabitParseResult(category: "recent", value: 1),
            createdAt: today
        )
        insertEvent(
            container: container,
            rawInput: "Old",
            payload: HabitParseResult(category: "old", value: 100),
            createdAt: fortyDaysAgo
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .last30Days
        await viewModel.refresh()

        #expect(viewModel.categoryTotals.count == 1)
        #expect(viewModel.categoryTotals.first?.category == "recent")
    }

    @Test func ignoresPendingAndFailedEvents() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(
            container: container,
            rawInput: "Parsed",
            payload: HabitParseResult(category: "a", value: 1),
            state: .parsed,
            createdAt: Date()
        )
        insertEvent(
            container: container,
            rawInput: "Pending",
            payload: nil,
            state: .pending,
            createdAt: Date()
        )
        insertEvent(
            container: container,
            rawInput: "Failed",
            payload: nil,
            state: .failed,
            createdAt: Date()
        )

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        #expect(viewModel.categoryTotals.count == 1)
        #expect(viewModel.categoryTotals.first?.category == "a")
    }

    @Test func computesCurrentStreak() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try #require(calendar.date(byAdding: .day, value: -2, to: today))

        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(container: container, rawInput: "A", payload: HabitParseResult(category: "a"), createdAt: today)
        insertEvent(container: container, rawInput: "B", payload: HabitParseResult(category: "b"), createdAt: yesterday)
        insertEvent(container: container, rawInput: "C", payload: HabitParseResult(category: "c"), createdAt: twoDaysAgo)

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        #expect(viewModel.currentStreak == 3)
    }

    @Test func streakBreaksOnMissingDay() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = try #require(calendar.date(byAdding: .day, value: -3, to: today))

        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(container: container, rawInput: "A", payload: HabitParseResult(category: "a"), createdAt: today)
        // Gap: yesterday and 2 days ago missing
        insertEvent(container: container, rawInput: "B", payload: HabitParseResult(category: "b"), createdAt: threeDaysAgo)

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        #expect(viewModel.currentStreak == 1)
    }

    @Test func insightsGeneratedForStreak() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let container = try ModelContainer.uniksContainer(inMemory: true)
        for offset in 0..<5 {
            let date = try #require(calendar.date(byAdding: .day, value: -offset, to: today))
            insertEvent(container: container, rawInput: "Event \(offset)", payload: HabitParseResult(category: "fitness"), createdAt: date)
        }

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        #expect(viewModel.currentStreak == 5)
        #expect(viewModel.insights.contains(where: { $0.text.contains("5-day streak") }))
    }

    @Test func topCategoryIsPopulated() async throws {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        insertEvent(container: container, rawInput: "A", payload: HabitParseResult(category: "fitness", value: 10), createdAt: Date())
        insertEvent(container: container, rawInput: "B", payload: HabitParseResult(category: "reading", value: 5), createdAt: Date())

        let viewModel = DashboardViewModel(container: container)
        viewModel.selectedRange = .allTime
        await viewModel.refresh()

        #expect(viewModel.topCategory == "fitness")
    }
}

// MARK: - Helpers

private func insertEvent(
    container: ModelContainer,
    rawInput: String,
    payload: HabitParseResult?,
    state: HabitEventState = .parsed,
    createdAt: Date
) {
    let context = ModelContext(container)
    let event = HabitEvent(rawInput: rawInput, state: state)
    event.createdAt = createdAt
    if let payload {
        event.setParsedPayload(payload)
    }
    context.insert(event)
    try? context.save()
}
