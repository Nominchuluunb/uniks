//
//  QuickInputViewModel.swift
//  uniks
//
//  View model for the quick input HUD/sheet with engine status and parse preview.
//

import Foundation
import Observation

/// Lightweight preview of the last parsed result for inline display.
struct ParsedPreview: Sendable {
    let category: String?
    let value: String?
    let unit: String?
}

@MainActor
@Observable
final class QuickInputViewModel {
    var text: String = ""
    var isSaving: Bool = false
    var errorMessage: String?
    var lastParsedPreview: ParsedPreview?

    var activeModelName: String {
        let modelID = ActiveModelPreference.effectiveModelID()
        return LocalModel.allModels.first(where: { $0.id == modelID })?.name ?? "Mock"
    }

    var engineStatus: UEngineStatusBadge.EngineStatusState {
        let pref = EnginePreference.current()
        switch pref {
        case .mlx:
            return .ready
        case .ollama:
            return .ready
        case .mock:
            return .mock
        }
    }

    private let service: HabitEventService
    var onSaved: (@MainActor () -> Void)?

    init(service: HabitEventService, onSaved: (@MainActor () -> Void)? = nil) {
        self.service = service
        self.onSaved = onSaved
    }

    func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        lastParsedPreview = nil
        defer { isSaving = false }

        do {
            let event = try await service.log(rawInput: trimmed)
            // Show inline preview if parsed data is available
            if let payload = event.parsedPayloadJSON,
               let data = payload.data(using: .utf8),
               let result = try? JSONDecoder().decode(HabitParseResult.self, from: data) {
                lastParsedPreview = ParsedPreview(
                    category: result.category,
                    value: result.value.map { String(format: "%g", $0) },
                    unit: result.unit
                )
            }
            text = ""
            // Delay dismiss to show preview briefly
            try? await Task.sleep(for: .milliseconds(800))
            onSaved?()
        } catch {
            errorMessage = "Could not save event."
        }
    }
}
