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
    private let parsingActor: any ParsingActorProtocol
    private let ftsService: any FTSServiceProtocol

    init(
        container: ModelContainer,
        parsingActor: any ParsingActorProtocol,
        ftsService: any FTSServiceProtocol
    ) {
        self.container = container
        self.parsingActor = parsingActor
        self.ftsService = ftsService
    }

    /// Saves the raw event, indexes it for search, and triggers background parsing.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: The stable identifier of the inserted event.
    func log(rawInput: String) async throws -> UUID {
        let context = ModelContext(self.container)
        let event = HabitEvent(rawInput: rawInput)
        context.insert(event)
        try context.save()

        let eventID = event.id
        let raw = event.rawInput

        try await self.ftsService.index(eventID: eventID, rawInput: raw)

        // Background parsing must not block the return of the event ID.
        Task {
            await self.parsingActor.parseAndSave(eventID: eventID)
        }

        return eventID
    }

    /// Updates the parsed payload of an existing event and marks it as `.parsed`.
    /// - Parameters:
    ///   - eventID: The stable identifier of the event to update.
    ///   - payload: The corrected structured payload.
    func update(eventID: UUID, payload: HabitParseResult) async throws {
        let context = ModelContext(self.container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try context.fetch(descriptor).first else {
            return
        }
        event.setParsedPayload(payload)
        try context.save()
    }

    /// Re-queues an event for background parsing.
    /// - Parameter eventID: The stable identifier of the event to retry.
    func retryParsing(eventID: UUID) async throws {
        let context = ModelContext(self.container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try context.fetch(descriptor).first else {
            return
        }
        event.state = .pending
        try context.save()

        Task {
            await self.parsingActor.parseAndSave(eventID: eventID)
        }
    }

    /// Deletes an event from SwiftData and the FTS index.
    ///
    /// - Parameter eventID: The stable identifier of the event to delete.
    ///   If no event exists for this identifier, the method returns without throwing.
    func delete(eventID: UUID) async throws {
        let context = ModelContext(self.container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try context.fetch(descriptor).first else {
            return
        }
        context.delete(event)
        try context.save()

        try await self.ftsService.remove(eventID: eventID)
    }
}
