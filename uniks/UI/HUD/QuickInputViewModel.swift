//
//  QuickInputViewModel.swift
//  uniks
//
//  View model for the quick input HUD/sheet with engine status and parse preview.
//

import Foundation
import Observation
#if os(iOS)
import UIKit
#endif

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
    var recentCategories: [String] = []
    var templates: [QuickLogTemplate] = []

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
        templates = QuickLogTemplateStore.load()
        Task { await loadRecentCategories() }
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
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            onSaved?()
        } catch {
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
            errorMessage = "Could not save event."
        }
    }

    private func loadRecentCategories() async {
        do {
            let categories = try await service.recentCategories(limit: 5)
            recentCategories = categories
        } catch {
            recentCategories = []
        }
    }
}
