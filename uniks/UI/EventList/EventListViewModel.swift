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

    private let ftsService: any FTSServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(ftsService: any FTSServiceProtocol) {
        self.ftsService = ftsService
    }

    func search() {
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            guard let self else { return }

            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                searchResults = []
                return
            }

            isSearching = true
            defer { isSearching = false }

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
    }
}
