//
//  ModelContainer+Factory.swift
//  uniks
//
//  Centralized SwiftData container configuration.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Creates the canonical SwiftData container for Uniks.
    /// - Parameter inMemory: When `true`, uses an in-memory store (useful for previews and tests).
    /// - Returns: A configured `ModelContainer` for `HabitEvent`.
    static func uniksContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([HabitEvent.self, Goal.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
