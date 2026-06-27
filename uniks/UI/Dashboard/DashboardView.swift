//
//  DashboardView.swift
//  uniks
//
//  Dashboard with charts and summaries for logged events.
//

import SwiftUI
import SwiftData
import Charts

@MainActor
struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing(.large)) {
                    Picker("Range", selection: $viewModel.selectedRange) {
                        ForEach(DashboardDateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, .spacing(.medium))

                    if hasData {
                        // Hero stat row
                        HStack(spacing: .spacing(.small)) {
                            UStatBox(
                                icon: "calendar",
                                value: "\(viewModel.totalEvents)",
                                label: "Total Events",
                                trend: viewModel.totalEvents > 0 ? .up : .neutral
                            )
                            UStatBox(
                                icon: "flame.fill",
                                value: viewModel.currentStreak > 0
                                    ? "\(viewModel.currentStreak) day\(viewModel.currentStreak == 1 ? "" : "s")"
                                    : "—",
                                label: "Current Streak",
                                trend: viewModel.currentStreak >= 3 ? .up : .neutral,
                                tint: .warning
                            )
                            UStatBox(
                                icon: "star.fill",
                                value: viewModel.topCategory ?? "—",
                                label: "Top Category",
                                tint: .brandPurple
                            )
                        }
                        .padding(.horizontal, .spacing(.medium))

                        // Insights
                        if !viewModel.insights.isEmpty {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                ForEach(viewModel.insights) { insight in
                                    HStack(spacing: .spacing(.xSmall)) {
                                        Image(systemName: insight.icon)
                                            .font(.uCaption)
                                            .foregroundStyle(Color.accent)
                                        Text(insight.text)
                                            .font(.uCallout)
                                            .foregroundStyle(Color.secondaryLabel)
                                    }
                                }
                            }
                            .padding(.spacing(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accentSubtle, in: RoundedRectangle(cornerRadius: .radius(.medium)))
                            .padding(.horizontal, .spacing(.medium))
                        }

                        CategoryTotalsCard(totals: viewModel.categoryTotals)
                            .padding(.horizontal, .spacing(.medium))
                        
                        DailyValuesCard(values: viewModel.dailyValues)
                            .padding(.horizontal, .spacing(.medium))
                        
                        TopTagsCard(tags: viewModel.topTags)
                            .padding(.horizontal, .spacing(.medium))
                        
                        DailyActivityCard(activity: viewModel.dailyActivity)
                            .padding(.horizontal, .spacing(.medium))
                    } else {
                        UEmptyState(
                            icon: Icons.emptyDashboard,
                            title: "No data yet",
                            message: "Log a few events and they’ll show up here."
                        )
                        .frame(minHeight: 300)
                    }
                }
                .padding(.vertical, .spacing(.medium))
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.refresh()
        }
    }

    private var hasData: Bool {
        !viewModel.categoryTotals.isEmpty
            || !viewModel.dailyValues.isEmpty
            || !viewModel.topTags.isEmpty
            || !viewModel.dailyActivity.isEmpty
    }
}

private struct CategoryTotalsCard: View {
    let totals: [CategoryTotal]

    var body: some View {
        UCard(title: "Category Totals") {
            if totals.isEmpty {
                Text("No category data")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                Chart(totals) { total in
                    BarMark(
                        x: .value("Total", total.total),
                        y: .value("Category", total.category)
                    )
                    .foregroundStyle(Gradients.brand)
                    .cornerRadius(.radius(.small))
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.separator)
                        AxisValueLabel()
                            .font(.uCaption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.uCaption)
                    }
                }
                .accessibilityLabel("Category totals chart")
                .accessibilityValue("Totals across \(totals.count) categories")
                .frame(height: max(100, CGFloat(totals.count) * 36))
            }
        }
    }
}

private struct DailyValuesCard: View {
    let values: [DailyValue]

    var body: some View {
        UCard(title: "Daily Trend") {
            if values.isEmpty {
                Text("No data trend")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                Chart(values) { value in
                    AreaMark(
                        x: .value("Date", value.date, unit: .day),
                        y: .value("Value", value.total)
                    )
                    .foregroundStyle(Gradients.brandArea)
                    .interpolationMethod(.catmullRom(alpha: 0.5))

                    LineMark(
                        x: .value("Date", value.date, unit: .day),
                        y: .value("Value", value.total)
                    )
                    .foregroundStyle(Gradients.brand)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom(alpha: 0.5))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .font(.uCaption2)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.separatorFaint)
                        AxisValueLabel()
                            .font(.uNumeric)
                    }
                }
                .accessibilityLabel("Daily trend chart")
                .accessibilityValue("Values over \(values.count) days")
                // swiftlint:disable:next hardcoded_frame_size
                .frame(height: 140)
            }
        }
    }
}

private struct TopTagsCard: View {
    let tags: [TagCount]

    var body: some View {
        UCard(title: "Top Tags") {
            if tags.isEmpty {
                Text("No tags logged yet")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                UFlowLayout(spacing: .small) {
                    ForEach(tags) { tag in
                        UChip(text: "\(tag.tag) (\(tag.count))", style: .tag)
                            .interactiveScale()
                    }
                }
            }
        }
    }
}

private struct DailyActivityCard: View {
    let activity: [DailyActivity]

    var body: some View {
        UCard(title: "Daily Activity") {
            if activity.isEmpty {
                Text("No activity data")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                VStack(alignment: .leading, spacing: .spacing(.small)) {
                    Chart(activity) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Events", day.count)
                        )
                        .foregroundStyle(Gradients.success)
                        .cornerRadius(.radius(.small))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            // Muted x axis for visual density
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.separator)
                            AxisValueLabel()
                                .font(.uCaption2)
                        }
                    }
                    .accessibilityLabel("Daily activity chart")
                    .accessibilityValue("Event counts over \(activity.count) days")
                    // swiftlint:disable:next hardcoded_frame_size
                    .frame(height: 100)

                    HStack(spacing: .spacing(.xxSmall)) {
                        Image(systemName: Icons.success)
                            .font(.uCaption)
                            .foregroundStyle(Color.positive)
                        Text("\(activity.reduce(0) { $0 + $1.count }) total events logged")
                            .font(.uCaption)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                }
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        return DashboardView(viewModel: DashboardViewModel(container: container))
    } catch {
        return Text("Preview failed")
    }
}
