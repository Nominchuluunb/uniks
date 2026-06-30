//
//  HabitEvent.swift
//  uniks
//
//  Canonical SwiftData model for a logged habit or event.
//

import Foundation
import SwiftData

/// The persisted state of a habit event.
enum HabitEventState: String, Codable, Sendable {
    case pending
    case heuristicParsed
    case parsed
    case enriched
    case failed
}

/// A single user log entry.
///
/// The raw input is always preserved. Structured fields are stored as JSON
/// in `parsedPayloadJSON` so the schema can evolve without SwiftData migrations.
@Model
final class HabitEvent {
    @Attribute(.unique) var id: UUID
    var rawInput: String
    var stateRaw: String
    var parsedPayloadJSON: String?
    var enrichmentJSON: String?
    var createdAt: Date
    var updatedAt: Date

    init(rawInput: String, state: HabitEventState = .pending) {
        self.id = UUID()
        self.rawInput = rawInput
        self.stateRaw = state.rawValue
        self.parsedPayloadJSON = nil
        self.enrichmentJSON = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension HabitEvent {
    /// The current parsing state, backed by `stateRaw`.
    var state: HabitEventState {
        get { HabitEventState(rawValue: stateRaw) ?? .pending }
        set {
            stateRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// Whether the event has any parsed data (heuristic, LLM, or enriched).
    var isParsed: Bool {
        state == .parsed || state == .heuristicParsed || state == .enriched
    }

    /// Stores a structured parse result and transitions state to `.parsed`.
    /// On encoding failure, transitions to `.failed`.
    func setParsedPayload(_ payload: HabitParseResult) {
        do {
            parsedPayloadJSON = try payload.toJSON()
            state = .parsed
        } catch {
            parsedPayloadJSON = nil
            state = .failed
        }
    }

    /// Returns the decoded structured payload, if any.
    func parsedPayload() -> HabitParseResult? {
        guard let parsedPayloadJSON else { return nil }
        return try? HabitParseResult.fromJSON(parsedPayloadJSON)
    }
}
