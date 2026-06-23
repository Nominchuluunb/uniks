//
//  EventListViewModel.swift
//  uniks
//
//  View model for the searchable event list.
//

import Foundation
import Observation

@MainActor
@Observable
final class EventListViewModel {
    var searchText: String = ""
    var searchResults: [UUID] = []
    var isSearching: Bool = false

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

            let trimmed = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                guard self.searchTask === task else { return }
                self.searchResults = []
                self.isSearching = false
                return
            }

            guard self.searchTask === task else { return }
            self.isSearching = true
            defer { if self.searchTask === task { self.isSearching = false } }

            do {
                let results = try await self.ftsService.search(query: trimmed)
                try Task.checkCancellation()
                guard self.searchTask === task else { return }
                self.searchResults = results
            } catch is CancellationError {
                // no-op
            } catch {
                guard self.searchTask === task else { return }
                self.searchResults = []
            }
        }
        searchTask = task
    }
}
