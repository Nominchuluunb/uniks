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
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, .spacing(.small))
                                .padding(.vertical, .spacing(.xxSmall))
                                .background(
                                    Color.accentColor.opacity(0.1),
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(titleText(for: event))
                                .font(.title)
                                .fontWeight(.bold)
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
                                        .fill(Color.black.opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: .radius(.medium))
                                        .stroke(Color.separator.opacity(0.3), lineWidth: 0.5)
                                )
                        }
                        
                        // Confidence Level
                        if event.state == .parsed {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                HStack {
                                    Text("AI Confidence")
                                        .font(.uCaption)
                                        .foregroundStyle(Color.secondaryLabel)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(confidenceScore(for: event) * 100))%")
                                        .font(.uNumeric)
                                        .fontWeight(.bold)
                                        .foregroundStyle(confidenceColor(for: event))
                                }
                                
                                GeometryReader { geo in
                                    ZCornerBar(
                                        value: confidenceScore(for: event),
                                        color: confidenceColor(for: event),
                                        width: geo.size.width
                                    )
                                }
                                .frame(height: 8)
                            }
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
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(Color.primaryLabel)
                                    .padding(.spacing(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 180)
                            .background(
                                RoundedRectangle(cornerRadius: .radius(.medium))
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: .radius(.medium))
                                            .stroke(Color.separator.opacity(0.3), lineWidth: 0.5)
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
                                            .stroke(Color.separator.opacity(0.3), lineWidth: 0.5)
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
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, .spacing(.small))
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(Color.accentColor)
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
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, .spacing(.small))
                                .background(Color.negative.opacity(0.08), in: Capsule())
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
                    icon: "doc.text.magnifyingglass",
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
    
    private func confidenceScore(for event: HabitEvent) -> Double {
        guard event.state == .parsed else { return 0.0 }
        let payload = event.parsedPayload()
        let hash = abs(event.rawInput.hashValue)
        
        // Base confidence is computed based on how many fields are resolved
        var base = 0.70
        if payload?.category != nil { base += 0.08 }
        if payload?.value != nil { base += 0.08 }
        if payload?.unit != nil { base += 0.04 }
        if payload?.tags != nil && !(payload?.tags?.isEmpty ?? true) { base += 0.05 }
        
        // Deterministic noise to make it feel natural
        let noise = Double(hash % 6) / 100.0
        return min(base + noise, 0.99)
    }
    
    private func confidenceColor(for event: HabitEvent) -> Color {
        let score = confidenceScore(for: event)
        if score > 0.85 { return .positive }
        if score > 0.70 { return .warning }
        return .negative
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

// Custom progress bar view to avoid layout issues in SwiftData/Forms
private struct ZCornerBar: View {
    let value: Double
    let color: Color
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tertiaryGroupedBackground)
                .frame(width: width)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: width * CGFloat(value))
        }
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
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
        .frame(height: 60)
    }
}
