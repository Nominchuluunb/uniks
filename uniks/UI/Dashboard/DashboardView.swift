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
