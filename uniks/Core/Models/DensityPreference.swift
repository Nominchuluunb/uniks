//
//  DensityPreference.swift
//  uniks
//
//  Layout density preference for macOS three-pane view.
//

import Foundation

/// Layout density modes for the macOS event list and inspector.
enum DensityPreference: String, CaseIterable, Sendable {
    case comfortable
    case compact

    var displayName: String {
        switch self {
        case .comfortable: return "Comfortable"
        case .compact: return "Compact"
        }
    }

    /// Row vertical padding multiplier.
    var paddingMultiplier: Double {
        switch self {
        case .comfortable: return 1.0
        case .compact: return 0.7
        }
    }

    // MARK: - Persistence

    private static let key = "uniks.densityPreference"

    static func current() -> DensityPreference {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let pref = DensityPreference(rawValue: raw) else {
            return .comfortable
        }
        return pref
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.key)
    }
}
