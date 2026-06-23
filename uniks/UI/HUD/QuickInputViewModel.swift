//
//  QuickInputViewModel.swift
//  uniks
//
//  View model for the quick input HUD/sheet.
//

import Foundation

@MainActor
@Observable
final class QuickInputViewModel {
    var text: String = ""
    var isSaving: Bool = false
    var errorMessage: String?

    private let service: HabitEventService
    private let onSaved: (() -> Void)?

    init(service: HabitEventService, onSaved: (() -> Void)? = nil) {
        self.service = service
        self.onSaved = onSaved
    }

    func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
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
