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
    /// - Returns: A configured `ModelContainer` for `HabitEvent` and `Goal`.
    static func uniksContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: UniksSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: UniksMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
