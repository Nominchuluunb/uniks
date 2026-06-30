//
//  EnrichmentActor.swift
//  uniks
//
//  Background enrichment agent that normalizes categories, detects patterns,
//  and links related events after LLM parsing completes.
//

import Foundation
import SwiftData

/// Enrichment metadata stored alongside events.
struct EnrichmentData: Codable, Sendable {
    var normalizedCategory: String?
    var relatedEventIDs: [String]?
    var patterns: [String]?
    var enrichedAt: Date?
}

/// Background actor responsible for post-parse enrichment:
/// - Category normalization (synonym resolution)
/// - Tag deduplication
/// - Related event detection
/// - Pattern detection (time-of-day, frequency)
///
/// Runs on a low-priority background task and never overwrites user corrections.
actor EnrichmentActor {
    private let container: ModelContainer

    /// Category synonym dictionary: maps variants to canonical names.
    static let categorySynonyms: [String: String] = [
        "run": "Fitness", "running": "Fitness", "ran": "Fitness",
        "jog": "Fitness", "jogging": "Fitness",
        "walk": "Fitness", "walking": "Fitness",
        "swim": "Fitness", "swimming": "Fitness",
        "cycle": "Fitness", "cycling": "Fitness",
        "workout": "Fitness", "exercise": "Fitness", "gym": "Fitness",
        "yoga": "Fitness", "stretch": "Fitness",
        "sport": "Fitness", "training": "Fitness",
        "sleep": "Sleep", "slept": "Sleep", "nap": "Sleep",
        "water": "Hydration", "hydration": "Hydration",
        "drink": "Hydration", "drank": "Hydration",
        "read": "Reading", "reading": "Reading", "book": "Reading",
        "meditate": "Meditation", "meditation": "Meditation",
        "food": "Diet", "eat": "Diet", "meal": "Diet",
        "breakfast": "Diet", "lunch": "Diet", "dinner": "Diet",
        "coffee": "Caffeine", "tea": "Caffeine", "espresso": "Caffeine",
        "money": "Finance", "spent": "Finance", "bought": "Finance",
        "expense": "Finance", "cost": "Finance",
        "mood": "Mood", "feeling": "Mood", "felt": "Mood",
        "work": "Work", "working": "Work", "meeting": "Work",
        "study": "Study", "studying": "Study", "learned": "Study",
        "friends": "Social", "family": "Social", "social": "Social",
        "creative": "Creative", "art": "Creative", "music": "Creative",
        "drive": "Transport", "commute": "Transport",
        "clean": "Chores", "laundry": "Chores", "cooking": "Chores"
    ]

    init(container: ModelContainer) {
        self.container = container
    }

    /// Enriches a single event by ID.
    /// - Parameter eventID: The event to enrich.
    func enrich(eventID: UUID) async {
        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )

        guard let event = try? context.fetch(descriptor).first else { return }

        // Skip if user has manually edited (updatedAt > createdAt + 1s means user edit)
        let timeSinceCreation = event.updatedAt.timeIntervalSince(event.createdAt)
        if timeSinceCreation > 60 && event.state == .parsed {
            // User likely edited; skip enrichment
            return
        }

        guard let payload = event.parsedPayload() else { return }

        var enrichment = existingEnrichment(for: event) ?? EnrichmentData()

        // 1. Category normalization
        if let category = payload.category {
            let normalized = normalizeCategory(category)
            if normalized != category {
                enrichment.normalizedCategory = normalized
                // Update the payload with normalized category
                var updatedPayload = payload
                updatedPayload.category = normalized
                event.setParsedPayload(updatedPayload)
            }
        }

        // 2. Find related events
        if let category = payload.category ?? enrichment.normalizedCategory {
            let relatedIDs = findRelatedEvents(category: category, excludeID: eventID, context: context)
            if !relatedIDs.isEmpty {
                enrichment.relatedEventIDs = relatedIDs.map(\.uuidString)
            }
        }

        // 3. Detect patterns
        let patterns = detectPatterns(for: event, context: context)
        if !patterns.isEmpty {
            enrichment.patterns = patterns
        }

        enrichment.enrichedAt = Date()

        // Save enrichment data
        if let jsonData = try? JSONEncoder().encode(enrichment),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            event.enrichmentJSON = jsonString
            event.state = .enriched
        }

        try? context.save()
    }

    /// Batch enriches all events that haven't been enriched yet.
    /// - Parameter limit: Maximum number of events to process in one batch.
    func enrichBatch(limit: Int = 20) async {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.stateRaw == "parsed" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        guard let events = try? context.fetch(descriptor) else { return }

        for event in events {
            await enrich(eventID: event.id)
        }
    }

    // MARK: - Private Helpers

    private func normalizeCategory(_ category: String) -> String {
        let lower = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let canonical = Self.categorySynonyms[lower] {
            return canonical
        }
        // Check if it's already a canonical category
        if ParsingPrompts.categoryTaxonomy.contains(where: { $0.lowercased() == lower }) {
            return ParsingPrompts.categoryTaxonomy.first(where: { $0.lowercased() == lower }) ?? category
        }
        return category.capitalized
    }

    private func findRelatedEvents(category: String, excludeID: UUID, context: ModelContext) -> [UUID] {
        let descriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let events = try? context.fetch(descriptor) else { return [] }

        return events
            .filter { $0.id != excludeID }
            .filter { $0.parsedPayload()?.category?.lowercased() == category.lowercased() }
            .prefix(5)
            .map(\.id)
    }

    private func detectPatterns(for event: HabitEvent, context: ModelContext) -> [String] {
        var patterns: [String] = []
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.createdAt)

        guard let category = event.parsedPayload()?.category else { return patterns }

        // Time-of-day pattern
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<22: timeOfDay = "evening"
        default: timeOfDay = "night"
        }
        patterns.append("logged_\(timeOfDay)")

        // Check for streak
        let descriptor = FetchDescriptor<HabitEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let events = try? context.fetch(descriptor) {
            let categoryEvents = events.filter {
                $0.parsedPayload()?.category?.lowercased() == category.lowercased()
            }
            if categoryEvents.count >= 3 {
                patterns.append("frequent_\(category.lowercased())")
            }
        }

        return patterns
    }

    private func existingEnrichment(for event: HabitEvent) -> EnrichmentData? {
        guard let json = event.enrichmentJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(EnrichmentData.self, from: data)
    }
}
