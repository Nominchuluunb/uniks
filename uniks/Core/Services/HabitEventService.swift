//
//  HabitEventService.swift
//  uniks
//
//  Coordinates optimistic persistence, search indexing, and background parsing.
//

import Foundation
import SwiftData

/// Service responsible for the end-to-end habit event ingestion path.
actor HabitEventService {
    private let container: ModelContainer
    private let parsingActor: ParsingActor
    private let ftsService: FTSService

    init(container: ModelContainer, parsingActor: ParsingActor, ftsService: FTSService) {
        self.container = container
        self.parsingActor = parsingActor
        self.ftsService = ftsService
    }

    /// Saves the raw event, indexes it for search, and triggers background parsing.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: The stable identifier of the inserted event.
    func log(rawInput: String) async throws -> UUID {
        let context = ModelContext(container)
        let event = HabitEvent(rawInput: rawInput)
        context.insert(event)
        try context.save()

        let eventID = event.id
        let raw = event.rawInput

        try await ftsService.index(eventID: eventID, rawInput: raw)

        // Background parsing must not block the return of the event ID.
        Task {
            await parsingActor.parseAndSave(eventID: eventID)
        }

        return eventID
    }

    /// Deletes an event from SwiftData and the FTS index.
    /// - Parameter eventID: The stable identifier of the event to delete.
    func delete(eventID: UUID) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })
        guard let event = try context.fetch(descriptor).first else {
            return
        }
        context.delete(event)
        try context.save()

        try await ftsService.remove(eventID: eventID)
    }
}
