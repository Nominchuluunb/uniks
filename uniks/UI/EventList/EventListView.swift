//
//  EventListView.swift
//  uniks
//
//  Searchable chronological list of habit events.
//

import SwiftUI
import SwiftData

struct EventGroup: Identifiable {
    let id = UUID()
    let title: String
    let events: [HabitEvent]
}

struct EventListView: View {
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]

    @State private var viewModel: EventListViewModel
    
    // For macOS NavigationSplitView integration
    var sidebarSelection: SidebarSelection?
    var selectedEventBinding: Binding<HabitEvent?>?

    // For iOS internal sheet presentation
    @State private var selectedEvent: HabitEvent?

    init(
        viewModel: EventListViewModel,
        sidebarSelection: SidebarSelection? = nil,
        selectedEventBinding: Binding<HabitEvent?>? = nil
    ) {
        self.viewModel = viewModel
        self.sidebarSelection = sidebarSelection
        self.selectedEventBinding = selectedEventBinding
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    #if os(iOS)
                    List {
                        ForEach(groupedEvents) { group in
                            Section {
                                ForEach(group.events) { event in
                                    EventRowCard(event: event)
                                        .onTapGesture {
                                            selectedEvent = event
                                        }
                                        .listRowInsets(EdgeInsets(
                                            top: .spacing(.xxSmall),
                                            leading: .spacing(.medium),
                                            bottom: .spacing(.xxSmall),
                                            trailing: .spacing(.medium)
                                        ))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { try? await viewModel.service.delete(eventID: event.id) }
                                            } label: {
                                                Label("Delete", systemImage: Icons.trash)
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            if event.state == .failed {
                                                Button {
                                                    Task {
                                                        try? await viewModel.service.retryParsing(eventID: event.id)
                                                    }
                                                } label: {
                                                    Label("Retry", systemImage: Icons.retry)
                                                }
                                                .tint(Color.accent)
                                            }
                                        }
                                }
                            } header: {
                                Text(group.title)
                                    .font(.uCaption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.groupedBackground)
                    .refreshable {
                        await viewModel.refresh()
                    }
                    #else
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(groupedEvents) { group in
                                Text(group.title)
                                    .font(.uCaption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .padding(.horizontal, .spacing(.medium))
                                    .padding(.top, .spacing(.large))
                                    .padding(.bottom, .spacing(.xxSmall))
                                
                                ForEach(group.events) { event in
                                    TimelineRow(
                                        event: event,
                                        isSelected: selectedEventBinding?.wrappedValue == event
                                    )
                                    .onTapGesture {
                                        if let selectedEventBinding {
                                            selectedEventBinding.wrappedValue = event
                                        } else {
                                            selectedEvent = event
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.leading, .spacing(.xxLarge))
                                }
                            }
                        }
                        .padding(.bottom, .spacing(.medium))
                    }
                    .background(Color.groupedBackground)
                    .refreshable {
                        await viewModel.refresh()
                    }
                    #endif
                }
            }
            .navigationTitle(navigationTitle)
            .searchable(text: $viewModel.searchText, prompt: "Search logs")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.search()
            }
            .sheet(item: $selectedEvent) { event in
                EventEditView(
                    event: event,
                    service: viewModel.service,
                    onFinished: { selectedEvent = nil }
                )
            }
        }
    }

    private var navigationTitle: String {
        #if os(macOS)
        if let sidebarSelection {
            return sidebarSelection.displayName
        }
        #endif
        return "Events"
    }

    private var filteredEvents: [HabitEvent] {
        let baseEvents: [HabitEvent]
        #if os(macOS)
        if let sidebarSelection {
            switch sidebarSelection {
            case .all:
                baseEvents = events
            case .inbox:
                baseEvents = events.filter { $0.state == .pending }
            case .category(let categoryName):
                baseEvents = events.filter { $0.parsedPayload()?.category?.lowercased() == categoryName.lowercased() }
            default:
                baseEvents = events
            }
        } else {
            baseEvents = events
        }
        #else
        baseEvents = events
        #endif

        if !viewModel.isSearchActive {
            return baseEvents
        }
        let resultIDs = Set(viewModel.searchResults)
        return baseEvents.filter { resultIDs.contains($0.id) }
    }

    private var groupedEvents: [EventGroup] {
        let calendar = Calendar.current
        var todayEvents: [HabitEvent] = []
        var yesterdayEvents: [HabitEvent] = []
        var earlierEvents: [HabitEvent] = []
        
        for event in filteredEvents {
            if calendar.isDateInToday(event.createdAt) {
                todayEvents.append(event)
            } else if calendar.isDateInYesterday(event.createdAt) {
                yesterdayEvents.append(event)
            } else {
                earlierEvents.append(event)
            }
        }
        
        var groups: [EventGroup] = []
        if !todayEvents.isEmpty {
            groups.append(EventGroup(title: "TODAY", events: todayEvents))
        }
        if !yesterdayEvents.isEmpty {
            groups.append(EventGroup(title: "YESTERDAY", events: yesterdayEvents))
        }
        if !earlierEvents.isEmpty {
            groups.append(EventGroup(title: "EARLIER THIS WEEK", events: earlierEvents))
        }
        return groups
    }

    private var eventListHint: String {
        #if os(iOS)
        "Tap + to log your first event."
        #else
        "Press Cmd + Shift + U or click + to log your first event."
        #endif
    }

    private var emptyStateView: some View {
        if viewModel.isSearchActive {
            return UEmptyState(
                icon: Icons.inspector,
                title: "No matches",
                message: "Try a different search term."
            )
        } else {
            return UEmptyState(
                icon: Icons.emptyEvents,
                title: "No events yet",
                message: eventListHint
            )
        }
    }
}

private struct EventRowCard: View {
    let event: HabitEvent

    var body: some View {
        HStack(alignment: .top, spacing: .spacing(.medium)) {
            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Text(event.rawInput)
                    .font(.uBody)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryLabel)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if event.state == .parsed || event.state == .heuristicParsed || event.state == .enriched,
                   let payload = event.parsedPayload() {
                    ParsedMetadataView(payload: payload, rawInput: event.rawInput)
                } else if event.state == .pending {
                    HStack(spacing: .spacing(.xxSmall)) {
                        ProgressView()
                            .controlSize(.small)
                        Text("AI Parsing…")
                            .font(.uCaption)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: .spacing(.small)) {
                UBadge(state: event.state)
                
                Text(event.createdAt, style: .time)
                    .font(.uNumeric)
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double-tap to edit this event.")
    }
}

private struct ParsedMetadataView: View {
    let payload: HabitParseResult
    var rawInput: String = ""

    var body: some View {
        UFlowLayout {
            if let category = payload.category {
                UChip(text: category, style: .category)
            }

            if payload.value != nil || payload.unit != nil {
                UChip(text: valueText, style: .value)
            }

            if let tags = payload.tags, !tags.isEmpty {
                ForEach(tags, id: \.self) { tag in
                    UChip(text: tag, style: .tag)
                }
            }

            // Only show notes that add information beyond the raw input itself.
            if let notes = payload.notes, !notes.isEmpty,
               !rawInput.localizedCaseInsensitiveContains(notes) {
                Text(notes)
                    .font(.uCaption)
                    .foregroundStyle(Color.secondaryLabel)
                    .lineLimit(1)
            }
        }
    }

    private var valueText: String {
        let value = payload.value.map { String($0) } ?? ""
        let unit = payload.unit ?? ""
        switch (!value.isEmpty, !unit.isEmpty) {
        case (true, true): return "\(value) \(unit)"
        case (true, false): return value
        case (false, true): return unit
        case (false, false): return ""
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        return EventListView(
            viewModel: EventListViewModel(
                service: HabitEventService(
                    container: container,
                    parsingActor: ParsingActor(
                        container: container,
                        engine: MockLLMEngine(result: HabitParseResult())
                    ),
                    ftsService: FTSService.inMemory()
                ),
                ftsService: FTSService.inMemory()
            )
        )
    } catch {
        return Text("Preview failed")
    }
}

private struct TimelineRow: View {
    let event: HabitEvent
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        let payload = event.parsedPayload()
        let category = payload?.category
        let categoryColor = Color.categoryColor(for: category)

        HStack(spacing: 0) {
            // Left category color vertical indicator bar
            Rectangle()
                .fill(categoryColor)
                .frame(width: .sizing(.categoryIndicatorWidth))

            HStack(alignment: .top, spacing: .spacing(.small)) {
                // Category icon
                Image(systemName: Icons.categorySymbol(for: category))
                    .font(.uBrandTitle2)
                    .foregroundStyle(categoryColor)
                    .frame(width: .sizing(.categoryIconSize), height: .sizing(.categoryIconSize))
                    .padding(.top, .spacing(.xxxSmall))

                // Content
                VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                    Text(event.rawInput)
                        .font(.uBody)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(Color.primaryLabel)

                    if event.state == .parsed || event.state == .heuristicParsed || event.state == .enriched, let payload {
                        HStack(spacing: .spacing(.xSmall)) {
                            if let val = payload.value {
                                Text("\(val, format: .number) \(payload.unit ?? "")")
                                    .font(.uCaption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(categoryColor)
                            }

                            if let tags = payload.tags, !tags.isEmpty {
                                ForEach(tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.uCaption2)
                                        .foregroundStyle(Color.secondaryLabel)
                                }
                            }
                        }
                    } else if event.state == .pending {
                        Text("AI parsing in progress...")
                            .font(.uCaption)
                            .foregroundStyle(Color.secondaryLabel)
                            .italic()
                    }
                }

                Spacer()

                // Right aligned metadata
                VStack(alignment: .trailing, spacing: .spacing(.xxSmall)) {
                    Text(event.createdAt, style: .time)
                        .font(.uNumeric)
                        .foregroundStyle(Color.secondaryLabel)

                    UBadge(state: event.state)
                }
            }
            .padding(.horizontal, .spacing(.medium))
            .padding(.vertical, .spacing(.small))
        }
        .background(
            isSelected ? Color.accentSubtle :
            (isHovered ? Color.tertiaryGroupedBackgroundFaint : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double-tap to inspect this event.")
    }
}
