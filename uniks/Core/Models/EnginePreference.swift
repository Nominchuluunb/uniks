//
//  EnginePreference.swift
//  uniks
//
//  User-selected local NLP engine with UserDefaults persistence.
//

import Foundation

/// The user's preferred local NLP engine.
enum EnginePreference: String, CaseIterable, Sendable {
    case mlx = "MLX"
    case ollama = "Ollama"
    case mock = "Mock"

    /// User-facing label.
    var displayName: String { rawValue }
}

extension EnginePreference {
    private static let userDefaultsKey = "uniks.enginePreference"

    /// Reads the persisted preference, defaulting to `.mlx`.
    static func current() -> EnginePreference {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
            let preference = EnginePreference(rawValue: rawValue)
        else {
            return .mlx
        }
        return preference
    }

    /// Persists the preference.
    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}
