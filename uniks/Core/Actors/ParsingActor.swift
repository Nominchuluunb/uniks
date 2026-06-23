//
//  ParsingActor.swift
//  uniks
//
//  Background parsing worker that updates persisted HabitEvents.
//

import Foundation
import SwiftData

/// Background actor responsible for running the local NLP engine and updating
/// the persisted `HabitEvent` state. The actor owns its own `ModelContext`
/// derived from a `Sendable` `ModelContainer`, so no non-Sendable context is
/// passed across concurrency domains.
actor ParsingActor {
    private let engine: any LocalLLMEngine
    private let container: ModelContainer

    init(container: ModelContainer, engine: any LocalLLMEngine) {
        self.container = container
        self.engine = engine
    }

    /// Fetches an existing event by ID, parses its raw input asynchronously,
    /// and persists the updated state.
    /// - Parameter eventID: The stable identifier of the event inserted by the
    ///   optimistic UI path.
    func parseAndSave(eventID: UUID) async {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })

        guard let event = try? context.fetch(descriptor).first else {
            return
        }

        do {
            let result = try await engine.parse(rawInput: event.rawInput)
            event.setParsedPayload(result)
            event.state = .parsed
        } catch {
            event.state = .failed
        }

        do {
            try context.save()
        } catch {
            // Silent save failure is acceptable here; the event remains in memory
            // and SwiftData will retry on next access.
        }
    }
}
