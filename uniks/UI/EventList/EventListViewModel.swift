//
//  EventListViewModel.swift
//  uniks
//
//  View model for the searchable event list.
//

import Foundation

@MainActor
@Observable
final class EventListViewModel {
    var searchText: String = ""
    var searchResults: [UUID] = []
    var isSearching: Bool = false

    var isSearchActive: Bool {
        !searchText.isEmpty || !searchResults.isEmpty
    }

    private let ftsService: any FTSServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(ftsService: any FTSServiceProtocol) {
        self.ftsService = ftsService
    }

    func search() {
        searchTask?.cancel()

        let task = Task { [weak self] in
            guard let self else { return }

            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                searchResults = []
                isSearching = false
                return
            }

            isSearching = true
            defer { if searchTask === task { isSearching = false } }

            do {
                let results = try await ftsService.search(query: trimmed)
                try Task.checkCancellation()
                searchResults = results
            } catch is CancellationError {
                // no-op
            } catch {
                searchResults = []
            }
        }
        searchTask = task
    }
}
