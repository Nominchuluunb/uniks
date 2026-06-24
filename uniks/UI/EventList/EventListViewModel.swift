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

    let service: HabitEventService
    private let ftsService: any FTSServiceProtocol
    private var searchTaskID: UInt = 0

    init(service: HabitEventService, ftsService: any FTSServiceProtocol) {
        self.service = service
        self.ftsService = ftsService
    }

    func search() {
        searchTaskID += 1
        let taskID = searchTaskID

        Task { [weak self] in
            guard let self else { return }

            let trimmed = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                guard self.searchTaskID == taskID else { return }
                self.searchResults = []
                self.isSearching = false
                return
            }

            guard self.searchTaskID == taskID else { return }
            self.isSearching = true
            defer { if self.searchTaskID == taskID { self.isSearching = false } }

            do {
                let results = try await self.ftsService.search(query: trimmed)
                try Task.checkCancellation()
                guard self.searchTaskID == taskID else { return }
                self.searchResults = results
            } catch is CancellationError {
                // no-op
            } catch {
                guard self.searchTaskID == taskID else { return }
                self.searchResults = []
            }
        }
    }
}
