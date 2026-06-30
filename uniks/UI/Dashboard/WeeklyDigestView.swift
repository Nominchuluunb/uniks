//
//  WeeklyDigestView.swift
//  uniks
//
//  Auto-generated weekly summary with shareable card.
//

import SwiftUI
import SwiftData

struct WeeklyDigest: Sendable {
    let weekLabel: String
    let totalEvents: Int
    let streak: Int
    let topCategory: String?
    let topCategoryCount: Int
    let totalCategories: Int
    let comparisonToLastWeek: Int // positive = more, negative = fewer
}

@MainActor
struct WeeklyDigestCard: View {
    let digest: WeeklyDigest

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.medium)) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: .spacing(.xxxSmall)) {
                    Text("Weekly Digest")
                        .font(.uHeadline)
                    Text(digest.weekLabel)
                        .font(.uCaption)
                        .foregroundStyle(Color.secondaryLabel)
                }
                Spacer()
                Image(systemName: "calendar.badge.checkmark")
                    .font(.uBrandTitle2)
                    .foregroundStyle(Gradients.brand)
            }

            Divider()

            // Stats grid
            HStack(spacing: .spacing(.medium)) {
                digestStat(value: "\(digest.totalEvents)", label: "Events", icon: "list.bullet")
                digestStat(value: "\(digest.streak)", label: "Day Streak", icon: "flame.fill")
                digestStat(value: "\(digest.totalCategories)", label: "Categories", icon: "folder.fill")
            }

            // Top category
            if let top = digest.topCategory {
                HStack(spacing: .spacing(.xSmall)) {
                    Image(systemName: Icons.categorySymbol(for: top))
                        .foregroundStyle(Color.categoryColor(for: top))
                    Text("Top: \(top.capitalized) (\(digest.topCategoryCount) entries)")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }

            // Comparison
            if digest.comparisonToLastWeek != 0 {
                HStack(spacing: .spacing(.xxSmall)) {
                    Image(systemName: digest.comparisonToLastWeek > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.uCaption)
                        .foregroundStyle(digest.comparisonToLastWeek > 0 ? Color.positive : Color.negative)
                    Text("\(abs(digest.comparisonToLastWeek)) \(digest.comparisonToLastWeek > 0 ? "more" : "fewer") than last week")
                        .font(.uCaption)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }
        }
        .cardStyle()
    }

    private func digestStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: .spacing(.xxxSmall)) {
            Image(systemName: icon)
                .font(.uCaption)
                .foregroundStyle(Color.accent)
            Text(value)
                .font(.uHeadline)
            Text(label)
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Computes weekly digest from events.
@MainActor
func computeWeeklyDigest(container: ModelContainer) -> WeeklyDigest? {
    let context = ModelContext(container)
    let descriptor = FetchDescriptor<HabitEvent>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    guard let events = try? context.fetch(descriptor) else { return nil }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today),
          let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today) else { return nil }

    let thisWeek = events.filter { $0.createdAt >= weekStart && ($0.state == .parsed || $0.state == .heuristicParsed || $0.state == .enriched) }
    let lastWeek = events.filter { $0.createdAt >= lastWeekStart && $0.createdAt < weekStart && ($0.state == .parsed || $0.state == .heuristicParsed || $0.state == .enriched) }

    // Categories
    var catCounts: [String: Int] = [:]
    for event in thisWeek {
        if let cat = event.parsedPayload()?.category {
            catCounts[cat, default: 0] += 1
        }
    }
    let topCat = catCounts.max(by: { $0.value < $1.value })

    // Streak
    var streak = 0
    var day = today
    let allParsed = Set(events.filter { $0.state == .parsed || $0.state == .heuristicParsed || $0.state == .enriched }.map { calendar.startOfDay(for: $0.createdAt) })
    while allParsed.contains(day) {
        streak += 1
        guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
        day = prev
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    let weekLabel = "\(formatter.string(from: weekStart)) – \(formatter.string(from: today))"

    return WeeklyDigest(
        weekLabel: weekLabel,
        totalEvents: thisWeek.count,
        streak: streak,
        topCategory: topCat?.key,
        topCategoryCount: topCat?.value ?? 0,
        totalCategories: catCounts.count,
        comparisonToLastWeek: thisWeek.count - lastWeek.count
    )
}
