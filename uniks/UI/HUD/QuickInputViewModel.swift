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
            _ = try await service.log(rawInput: trimmed)
            text = ""
            onSaved?()
        } catch {
            errorMessage = "Could not save event."
        }
    }
}
