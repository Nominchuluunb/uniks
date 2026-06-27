//
//  QuickLogTemplate.swift
//  uniks
//
//  Saved phrases for one-tap logging.
//

import Foundation

/// A saved phrase template that can be logged with a single tap.
struct QuickLogTemplate: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var phrase: String
    var emoji: String

    init(phrase: String, emoji: String = "⚡") {
        self.id = UUID()
        self.phrase = phrase
        self.emoji = emoji
    }
}

/// Persistence for quick-log templates via UserDefaults.
enum QuickLogTemplateStore {
    private static let key = "uniks.quickLogTemplates"

    static func load() -> [QuickLogTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let templates = try? JSONDecoder().decode([QuickLogTemplate].self, from: data) else {
            return []
        }
        return templates
    }

    static func save(_ templates: [QuickLogTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func add(_ template: QuickLogTemplate) {
        var templates = load()
        templates.append(template)
        save(templates)
    }

    static func remove(id: UUID) {
        var templates = load()
        templates.removeAll { $0.id == id }
        save(templates)
    }
}
