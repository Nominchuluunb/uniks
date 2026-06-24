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
    case parsed
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
    var createdAt: Date
    var updatedAt: Date

    init(rawInput: String, state: HabitEventState = .pending) {
        self.id = UUID()
        self.rawInput = rawInput
        self.stateRaw = state.rawValue
        self.parsedPayloadJSON = nil
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

/// Predefined smart query filters for the sidebar.
enum SavedFilter: String, Hashable, CaseIterable, Sendable {
    case prsThisYear = "PRs this year"
    case civicServiceLog = "Civic — service log"
    case longRuns = "Long runs > 10km"
}

extension HabitEvent {
    /// Determines whether the event matches a specific smart filter.
    func matchesSavedFilter(_ filter: SavedFilter) -> Bool {
        let payload = self.parsedPayload()
        let rawLower = self.rawInput.lowercased()
        
        switch filter {
        case .prsThisYear:
            let isThisYear = Calendar.current.isDate(self.createdAt, equalTo: Date(), toGranularity: .year)
            let hasPR = rawLower.contains("pr") ||
                (payload?.tags?.contains { $0.lowercased() == "pr" } ?? false)
            return isThisYear && hasPR
            
        case .civicServiceLog:
            let hasCivic = rawLower.contains("civic")
            let hasService = rawLower.contains("service") ||
                rawLower.contains("log") ||
                (payload?.tags?.contains { $0.lowercased() == "service" } ?? false)
            return hasCivic || hasService
            
        case .longRuns:
            let isRun = rawLower.contains("run") ||
                payload?.category?.lowercased() == "fitness" ||
                (payload?.tags?.contains { $0.lowercased() == "run" } ?? false)
            let isLong = (payload?.value ?? 0.0) >= 10.0
            return isRun && isLong
        }
    }
}
