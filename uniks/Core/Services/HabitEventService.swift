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
    private let heuristicParser = HeuristicParser()

    init(
        container: ModelContainer,
        parsingActor: any ParsingActorProtocol,
        ftsService: any FTSServiceProtocol
    ) {
        self.container = container
        self.parsingActor = parsingActor
        self.ftsService = ftsService
    }

    /// Saves the raw event, indexes it for search, runs heuristic parse immediately,
    /// and triggers background LLM parsing for refinement.
    /// Automatically parses relative time expressions (e.g. "yesterday", "2 hours ago")
    /// to override the event timestamp.
    /// - Parameter rawInput: The user's original text.
    /// - Returns: The stable identifier of the inserted event.
    func log(rawInput: String) async throws -> UUID {
        let context = ModelContext(self.container)

        // Parse natural time references
        let timeResult = NaturalTimeParser.parse(rawInput)
        let effectiveInput = timeResult?.cleanedInput ?? rawInput

        let event = HabitEvent(rawInput: effectiveInput)
        if let resolved = timeResult?.resolvedDate {
            event.createdAt = resolved
        }

        // Stage 1: Fast heuristic parse (synchronous, < 5ms)
        let heuristicResult = heuristicParser.parse(rawInput: effectiveInput)
        if heuristicResult.category != nil || heuristicResult.value != nil {
            event.setParsedPayload(heuristicResult)
            event.state = .heuristicParsed
        }

        context.insert(event)
        try context.save()

        let eventID = event.id
        let raw = event.rawInput

        try await self.ftsService.index(eventID: eventID, rawInput: raw)

        // Stage 2+: Background LLM parsing for refinement
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

    /// Duplicates an event with a fresh timestamp and re-parses it.
    /// - Parameter eventID: The event to duplicate.
    /// - Returns: The new event's ID.
    func duplicate(eventID: UUID) async throws -> UUID {
        let context = ModelContext(self.container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let original = try context.fetch(descriptor).first else {
            throw HabitParseError.decodingFailed
        }
        return try await log(rawInput: original.rawInput)
    }

    /// Returns the most recently used categories for smart suggestions.
    /// - Parameter limit: Maximum number of categories to return.
    func recentCategories(limit: Int = 5) async throws -> [String] {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let events = try context.fetch(descriptor)
        var seen: Set<String> = []
        var result: [String] = []
        for event in events {
            guard let category = event.parsedPayload()?.category,
                  !category.isEmpty,
                  !seen.contains(category) else { continue }
            seen.insert(category)
            result.append(category)
            if result.count >= limit { break }
        }
        return result
    }

    // MARK: - Bulk Operations

    /// Deletes multiple events by IDs.
    /// - Parameter ids: The event IDs to delete.
    /// - Returns: Number of events actually deleted.
    @discardableResult
    func bulkDelete(ids: Set<UUID>) async throws -> Int {
        let context = ModelContext(self.container)
        var deleted = 0
        for id in ids {
            let idValue = id
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == idValue }
            )
            if let event = try? context.fetch(descriptor).first {
                context.delete(event)
                try? await self.ftsService.remove(eventID: id)
                deleted += 1
            }
        }
        try context.save()
        return deleted
    }

    /// Re-queues multiple events for background parsing.
    /// - Parameter ids: The event IDs to re-parse.
    func bulkRetryParsing(ids: Set<UUID>) async throws {
        let context = ModelContext(self.container)
        for id in ids {
            let idValue = id
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == idValue }
            )
            if let event = try? context.fetch(descriptor).first {
                event.state = .pending
            }
        }
        try context.save()

        for id in ids {
            Task {
                await self.parsingActor.parseAndSave(eventID: id)
            }
        }
    }

    /// Updates the category of multiple events.
    /// - Parameters:
    ///   - ids: The event IDs to update.
    ///   - category: The new category to assign.
    func bulkUpdateCategory(ids: Set<UUID>, category: String) async throws {
        let context = ModelContext(self.container)
        for id in ids {
            let idValue = id
            let descriptor = FetchDescriptor<HabitEvent>(
                predicate: #Predicate { $0.id == idValue }
            )
            if let event = try? context.fetch(descriptor).first {
                var payload = event.parsedPayload() ?? HabitParseResult()
                payload.category = category
                event.setParsedPayload(payload)
            }
        }
        try context.save()
    }
}
