//
//  EventListView.swift
//  uniks
//
//  Searchable chronological list of habit events.
//

import SwiftUI
import SwiftData

struct EventListView: View {
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]

    @State private var viewModel: EventListViewModel

    init(viewModel: EventListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List(filteredEvents) { event in
                EventRow(event: event)
            }
            .navigationTitle("Events")
            .searchable(text: $viewModel.searchText, prompt: "Search logs")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.search()
            }
        }
    }

    private var filteredEvents: [HabitEvent] {
        if viewModel.searchResults.isEmpty && viewModel.searchText.isEmpty {
            return events
        }
        let resultIDs = Set(viewModel.searchResults)
        return events.filter { resultIDs.contains($0.id) }
    }
}

private struct EventRow: View {
    let event: HabitEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.rawInput)
                .font(.body)
            HStack {
                StatusBadge(state: event.state)
                Spacer()
                Text(event.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
