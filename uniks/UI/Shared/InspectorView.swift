//
//  InspectorView.swift
//  uniks
//
//  Right pane detail inspector for macOS Three-Pane Split View.
//

import SwiftUI
import SwiftData
import Charts

struct InspectorView: View {
    let event: HabitEvent?
    let service: HabitEventService
    
    @Query(sort: \HabitEvent.createdAt, order: .forward) private var allEvents: [HabitEvent]
    @State private var isShowingEditSheet = false
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            if let event {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing(.large)) {
                        // Header
                        HStack {
                            Text("#\(event.id.uuidString.suffix(4).uppercased())")
                                .font(.uMonospacedTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, .spacing(.small))
                                .padding(.vertical, .spacing(.xxSmall))
                                .background(
                                    Color.accentSoft,
                                    in: RoundedRectangle(cornerRadius: .radius(.small))
                                )
                            
                            Spacer()
                            
                            Text("Detail Inspector")
                                .font(.uCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondaryLabel)
                                .textCase(.uppercase)
                                .tracking(1.0)
                        }
                        
                        // Large Title
                        VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                            Text(titleText(for: event))
                                .font(.uBrandTitle)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            
                            if let category = event.parsedPayload()?.category {
                                Text(category)
                                    .font(.uCallout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.categoryColor(for: category))
                            }
                        }
                        
                        // Raw Input Box
                        VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                            Text("Raw Input Log")
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Text(event.rawInput)
                                .font(.uBody)
                                .foregroundStyle(Color.primaryLabel)
                                .padding(.spacing(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: .radius(.medium))
                                        .fill(Color.codeBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: .radius(.medium))
                                        .stroke(Color.separatorFaint, lineWidth: 0.5)
                                )
                        }
                        
                        // Parsed Payload monospaced JSON block
                        VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                            Text("Parsed Payload (JSON)")
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            ScrollView([.horizontal, .vertical]) {
                                Text(formattedJSON(for: event))
                                    .font(.uMonospacedBody)
                                    .foregroundStyle(Color.primaryLabel)
                                    .padding(.spacing(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 180)
                            .background(
                                RoundedRectangle(cornerRadius: .radius(.medium))
                                    .fill(Color.codeBackgroundDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: .radius(.medium))
                                            .stroke(Color.separatorFaint, lineWidth: 0.5)
                                    )
                            )
                        }
                        
                        // Swift Charts Sparkline Graph
                        if event.state == .parsed,
                           let category = event.parsedPayload()?.category,
                           !sparklineEvents(for: category).isEmpty {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                Text("\(category) History (Last 8 logs)")
                                    .font(.uCaption)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                
                                ChartView(events: sparklineEvents(for: category), category: category)
                                    .padding(.spacing(.medium))
                                    .background(
                                        RoundedRectangle(cornerRadius: .radius(.medium))
                                            .fill(Color.secondaryGroupedBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: .radius(.medium))
                                            .stroke(Color.separatorFaint, lineWidth: 0.5)
                                    )
                            }
                        }
                        
                        Spacer()
                            .frame(height: .spacing(.large))
                        
                        // Bottom Actions
                        HStack(spacing: .spacing(.medium)) {
                            Button {
                                isShowingEditSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: Icons.pencil)
                                    Text("Edit")
                                }
                                .font(.uBody)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, .spacing(.small))
                                .background(Color.accentSoft, in: Capsule())
                                .foregroundStyle(Color.accent)
                            }
                            .buttonStyle(.plain)
                            .interactiveScale()
                            
                            Button(role: .destructive) {
                                isDeleting = true
                                Task {
                                    try? await service.delete(eventID: event.id)
                                    isDeleting = false
                                }
                            } label: {
                                HStack {
                                    if isDeleting {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: Icons.trash)
                                    }
                                    Text("Delete")
                                }
                                .font(.uBody)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, .spacing(.small))
                                .background(Color.negativeSubtle, in: Capsule())
                                .foregroundStyle(Color.negative)
                            }
                            .buttonStyle(.plain)
                            .interactiveScale()
                            .disabled(isDeleting)
                        }
                    }
                    .padding(.spacing(.large))
                }
            } else {
                UEmptyState(
                    icon: Icons.inspector,
                    title: "No Event Selected",
                    message: "Select an event from the timeline to view details, parsed payload, and metrics."
                )
                .frame(maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let event {
                EventEditView(
                    event: event,
                    service: service,
                    onFinished: { isShowingEditSheet = false }
                )
            }
        }
    }
    
    // MARK: - Helper Methods & Subviews
    
    private func titleText(for event: HabitEvent) -> String {
        guard event.state == .parsed, let payload = event.parsedPayload() else {
            return event.rawInput
        }

        let value = payload.value.map { String($0) } ?? ""
        let unit = payload.unit ?? ""

        switch (!value.isEmpty, !unit.isEmpty) {
        case (true, true): return "\(value) \(unit)"
        case (true, false): return value
        case (false, true): return unit
        case (false, false): return payload.category ?? event.rawInput
        }
    }

    private func formattedJSON(for event: HabitEvent) -> String {
        guard let payload = event.parsedPayload() else { return "{}" }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload),
              let prettyString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return prettyString
    }
    
    private func sparklineEvents(for category: String) -> [HabitEvent] {
        allEvents
            .filter {
                $0.state == .parsed &&
                $0.parsedPayload()?.category?.lowercased() == category.lowercased()
            }
            .suffix(8)
    }
}

// Sparkline Chart View using Swift Charts
private struct ChartView: View {
    let events: [HabitEvent]
    let category: String
    
    var body: some View {
        let categoryColor = Color.categoryColor(for: category)
        Chart {
            ForEach(Array(events.enumerated()), id: \.offset) { index, item in
                let val = item.parsedPayload()?.value ?? 1.0
                
                AreaMark(
                    x: .value("Log", index),
                    y: .value("Value", val)
                )
                .interpolationMethod(.catmullRom(alpha: 0.5))
                .foregroundStyle(Gradients.area(for: categoryColor))
                
                LineMark(
                    x: .value("Log", index),
                    y: .value("Value", val)
                )
                .interpolationMethod(.catmullRom(alpha: 0.5))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .foregroundStyle(categoryColor)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("\(category) history sparkline")
        .accessibilityValue("Last \(events.count) logged values")
        // swiftlint:disable:next hardcoded_frame_size
        .frame(height: 60)
    }
}
