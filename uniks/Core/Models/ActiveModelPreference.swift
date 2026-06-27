//
//  ActiveModelPreference.swift
//  uniks
//
//  Persists which downloaded model is the active parser.
//

import Foundation

/// UserDefaults-backed preference for the currently active on-device model.
enum ActiveModelPreference {
    private static let key = "uniks.activeModelID"

    /// Returns the stored active model ID, or nil if unset.
    static func current() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    /// Returns the effective model ID: stored preference if valid, otherwise the catalog default.
    static func effectiveModelID() -> String {
        if let stored = current(),
           LocalModel.allModels.contains(where: { $0.id == stored }) {
            return stored
        }
        return LocalModel.defaultModel.id
    }

    /// Persists the active model ID.
    static func setActive(_ id: String) {
        UserDefaults.standard.set(id, forKey: key)
    }

    /// Clears the active model preference (reverts to default).
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
