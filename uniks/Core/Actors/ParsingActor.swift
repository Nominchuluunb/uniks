//
//  ParsingActor.swift
//  uniks
//
//  Background parsing worker that updates persisted HabitEvents.
//

import Foundation
import SwiftData

/// Errors specific to the parsing pipeline.
enum ParsingError: Error, Sendable {
    case timeout
}

/// Protocol abstraction for background parsing actors so services can depend on
/// a capability rather than a concrete type.
protocol ParsingActorProtocol: Sendable {
    /// Fetches an existing event by ID, parses its raw input asynchronously,
    /// and persists the updated state.
    /// - Parameter eventID: The stable identifier of the event inserted by the
    ///   optimistic UI path.
    func parseAndSave(eventID: UUID) async
}

/// Background actor responsible for running the local NLP engine and updating
/// the persisted `HabitEvent` state. The actor owns its own `ModelContext`
/// derived from a `Sendable` `ModelContainer`, so no non-Sendable context is
/// passed across concurrency domains.
actor ParsingActor: ParsingActorProtocol {
    private let engine: any LocalLLMEngine
    private let container: ModelContainer

    init(container: ModelContainer, engine: any LocalLLMEngine) {
        self.container = container
        self.engine = engine
    }

    /// Fetches an existing event by ID, parses its raw input asynchronously,
    /// and persists the updated state.
    ///
    /// - Parameter eventID: The stable identifier of the event inserted by the
    ///   optimistic UI path.
    ///
    /// Fetch and save errors are handled silently: if the event cannot be
    /// fetched, the method returns early, leaving the event in its current
    /// state. If the final save fails, the event remains in memory and SwiftData
    /// will retry on next access.
    func parseAndSave(eventID: UUID) async {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<HabitEvent>(predicate: #Predicate { $0.id == eventID })

        guard let event = try? context.fetch(descriptor).first else {
            return
        }

        let rawInput = event.rawInput
        let engine = self.engine

        do {
            let result = try await withThrowingTaskGroup(of: HabitParseResult.self) { group in
                group.addTask {
                    try await engine.parse(rawInput: rawInput)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(60))
                    throw ParsingError.timeout
                }
                let first = try await group.next()!
                group.cancelAll()
                return first
            }
            event.setParsedPayload(result)
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
