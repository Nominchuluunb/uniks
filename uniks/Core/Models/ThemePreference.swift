//
//  ThemePreference.swift
//  uniks
//
//  User theme preference (system, light, dark) with persistence.
//

import SwiftUI

/// User's preferred color scheme.
enum ThemePreference: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    /// User-facing display name.
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// Converts to SwiftUI `ColorScheme` for `.preferredColorScheme()`.
    /// Returns nil for `.system` (follow system).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - Persistence

    private static let key = "uniks.themePreference"

    /// Reads the current preference from UserDefaults.
    static func current() -> ThemePreference {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let pref = ThemePreference(rawValue: raw) else {
            return .system
        }
        return pref
    }

    /// Saves this preference to UserDefaults.
    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.key)
    }
}
