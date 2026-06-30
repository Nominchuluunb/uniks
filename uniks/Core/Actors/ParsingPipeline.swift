//
//  ParsingPipeline.swift
//  uniks
//
//  Multi-agent parsing pipeline orchestrator.
//  Coordinates: Heuristic → Corrections → LLM → Enrichment → Final confidence.
//

import Foundation
import SwiftData

/// Orchestrates the full multi-stage parsing pipeline for habit events.
/// Each stage is independently cancellable. User edits cancel remaining stages.
///
/// Pipeline stages:
/// 1. Heuristic parse (synchronous, < 5ms) — already applied in HabitEventService.log()
/// 2. Corrections check — override if a similar past correction exists
/// 3. LLM parse (asynchronous) — full NLP extraction
/// 4. Enrichment (background) — normalize, link, detect patterns
/// 5. Final confidence aggregation
actor ParsingPipeline: ParsingActorProtocol {
    private let container: ModelContainer
    private let engine: any LocalLLMEngine
    private let correctionsStore: UserCorrectionsStore
    private let enrichmentActor: EnrichmentActor
    private let heuristicParser = HeuristicParser()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    init(
        container: ModelContainer,
        engine: any LocalLLMEngine,
        correctionsStore: UserCorrectionsStore,
        enrichmentActor: EnrichmentActor
    ) {
        self.container = container
        self.engine = engine
        self.correctionsStore = correctionsStore
        self.enrichmentActor = enrichmentActor
    }

    /// Convenience initializer that creates internal dependencies.
    init(container: ModelContainer, engine: any LocalLLMEngine) {
        self.container = container
        self.engine = engine
        self.correctionsStore = UserCorrectionsStore(container: container)
        self.enrichmentActor = EnrichmentActor(container: container)
    }

    /// Runs the full pipeline for an event.
    /// Conforms to `ParsingActorProtocol` for backward compatibility.
    func parseAndSave(eventID: UUID) async {
        // Cancel any existing pipeline for this event
        activeTasks[eventID]?.cancel()

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runPipeline(eventID: eventID)
        }
        activeTasks[eventID] = task
        await task.value
        activeTasks[eventID] = nil
    }

    /// Cancels the pipeline for a specific event (e.g., when user edits).
    func cancelPipeline(for eventID: UUID) {
        activeTasks[eventID]?.cancel()
        activeTasks[eventID] = nil
    }

    // MARK: - Pipeline Execution

    private func runPipeline(eventID: UUID) async {
        // Stage 2: Check corrections
        let correctionResult = await runCorrectionsStage(eventID: eventID)
        if Task.isCancelled { return }

        if let correction = correctionResult {
            // Correction found — apply it with high confidence and skip LLM
            await applyResult(correction, to: eventID, state: .parsed)
            // Still run enrichment
            await runEnrichmentStage(eventID: eventID)
            return
        }

        // Stage 3: LLM parse
        let llmResult = await runLLMStage(eventID: eventID)
        if Task.isCancelled { return }

        if let result = llmResult {
            await applyResult(result, to: eventID, state: .parsed)
        } else {
            // LLM failed — mark as failed only if no heuristic result exists
            await markFailedIfNoHeuristic(eventID: eventID)
        }

        if Task.isCancelled { return }

        // Stage 4: Enrichment (background, non-blocking)
        await runEnrichmentStage(eventID: eventID)
    }

    // MARK: - Stage 2: Corrections Check

    private func runCorrectionsStage(eventID: UUID) async -> HabitParseResult? {
        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try? context.fetch(descriptor).first else { return nil }

        // Check if a similar input has been corrected before
        if let correction = await correctionsStore.findMatchingCorrection(for: event.rawInput) {
            var result = correction
            result.confidence = 1.0 // User corrections are highest confidence
            return result
        }

        return nil
    }

    // MARK: - Stage 3: LLM Parse

    private func runLLMStage(eventID: UUID) async -> HabitParseResult? {
        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try? context.fetch(descriptor).first else { return nil }

        let rawInput = event.rawInput

        // Get relevant corrections for few-shot injection
        let corrections = await correctionsStore.relevantCorrections(for: rawInput, limit: 3)

        // Retry with exponential backoff: 0s, 2s, 10s
        let retryDelays: [Duration] = [.zero, .seconds(2), .seconds(10)]

        for (attempt, delay) in retryDelays.enumerated() {
            if attempt > 0 {
                try? await Task.sleep(for: delay)
                if Task.isCancelled { return nil }
            }

            do {
                let result = try await withThrowingTaskGroup(of: HabitParseResult.self) { group in
                    group.addTask { [engine] in
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

                // Ensure confidence is set
                var finalResult = result
                if finalResult.confidence == nil {
                    finalResult.confidence = 0.8
                }
                return finalResult
            } catch is CancellationError {
                return nil
            } catch {
                // Retry on next iteration
                continue
            }
        }

        return nil
    }

    // MARK: - Stage 4: Enrichment

    private func runEnrichmentStage(eventID: UUID) async {
        guard !Task.isCancelled else { return }
        await enrichmentActor.enrich(eventID: eventID)
    }

    // MARK: - Helpers

    private func applyResult(_ result: HabitParseResult, to eventID: UUID, state: HabitEventState) async {
        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try? context.fetch(descriptor).first else { return }
        event.setParsedPayload(result)
        event.state = state
        try? context.save()
    }

    private func markFailedIfNoHeuristic(eventID: UUID) async {
        let context = ModelContext(container)
        let eventIDValue = eventID
        let descriptor = FetchDescriptor<HabitEvent>(
            predicate: #Predicate { $0.id == eventIDValue }
        )
        guard let event = try? context.fetch(descriptor).first else { return }

        // Only mark as failed if there's no heuristic result already
        if event.state == .pending || event.parsedPayloadJSON == nil {
            event.state = .failed
            try? context.save()
        }
        // If heuristic result exists, leave it — better than nothing
    }
}
