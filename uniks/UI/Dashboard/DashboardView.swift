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

                        // Weekly Heatmap
                        WeeklyHeatmapCard(activity: viewModel.dailyActivity)
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

                        // Category sparklines
                        CategorySparklineCard(totals: viewModel.categoryTotals, dailyValues: viewModel.dailyValues)
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

private struct WeeklyHeatmapCard: View {
    let activity: [DailyActivity]

    var body: some View {
        UCard(title: "Activity Heatmap") {
            if activity.isEmpty {
                Text("No activity data")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                    // Day labels
                    HStack(spacing: .spacing(.xxxSmall)) {
                        ForEach(activity.suffix(28), id: \.id) { day in
                            Rectangle()
                                .fill(heatColor(for: day.count))
                                .frame(width: 12, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .accessibilityLabel("\(day.count) events on \(day.date.formatted(.dateTime.month(.abbreviated).day()))")
                        }
                    }

                    // Legend
                    HStack(spacing: .spacing(.xSmall)) {
                        Text("Less")
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                        ForEach(0..<5) { level in
                            Rectangle()
                                .fill(heatColor(for: level))
                                .frame(width: 10, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        Text("More")
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                    .padding(.top, .spacing(.xxSmall))
                }
            }
        }
    }

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.tertiaryGroupedBackground
        case 1: return Color.positive.opacity(0.25)
        case 2: return Color.positive.opacity(0.5)
        case 3: return Color.positive.opacity(0.75)
        default: return Color.positive
        }
    }
}

private struct CategorySparklineCard: View {
    let totals: [CategoryTotal]
    let dailyValues: [DailyValue]

    var body: some View {
        UCard(title: "Category Breakdown") {
            if totals.isEmpty {
                Text("No category data")
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
            } else {
                VStack(spacing: .spacing(.small)) {
                    ForEach(totals.prefix(5)) { total in
                        HStack(spacing: .spacing(.small)) {
                            Circle()
                                .fill(Color.categoryColor(for: total.category))
                                .frame(width: 8, height: 8)
                            Text(total.category)
                                .font(.uCaption)
                                .frame(width: 80, alignment: .leading)

                            // Mini sparkline
                            SparklineView(
                                values: sparklineData(for: total),
                                color: Color.categoryColor(for: total.category)
                            )
                            .frame(height: 20)

                            Text(String(format: "%.0f", total.total))
                                .font(.uNumeric)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primaryLabel)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func sparklineData(for total: CategoryTotal) -> [Double] {
        // Generate proportional sparkline from daily values
        dailyValues.suffix(7).map { $0.total }
    }
}

private struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if values.isEmpty || values.allSatisfy({ $0 == 0 }) {
                Path { path in
                    let y = geo.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(color.opacity(0.3), lineWidth: 1)
            } else {
                let maxVal = values.max() ?? 1
                let minVal = values.min() ?? 0
                let range = maxVal - minVal
                let normalizedRange = range == 0 ? 1.0 : range

                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / normalizedRange))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 1.5)
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
