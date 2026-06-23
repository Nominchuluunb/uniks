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

    init(ftsService: any FTSServiceProtocol) {
        self.ftsService = ftsService
    }

    func search() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await ftsService.search(query: trimmed)
        } catch {
            searchResults = []
        }
    }
}
