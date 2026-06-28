//
//  UniksSchemaVersions.swift
//  uniks
//
//  SwiftData versioned schemas and migration plan.
//

import Foundation
import SwiftData

// MARK: - V1: Original schema (HabitEvent only)

enum UniksSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [HabitEventV1.self]
    }

    @Model
    final class HabitEventV1 {
        @Attribute(.unique) var id: UUID
        var rawInput: String
        var stateRaw: String
        var parsedPayloadJSON: String?
        var createdAt: Date
        var updatedAt: Date

        init(rawInput: String) {
            self.id = UUID()
            self.rawInput = rawInput
            self.stateRaw = "pending"
            self.parsedPayloadJSON = nil
            self.createdAt = Date()
            self.updatedAt = Date()
        }
    }
}

// MARK: - V2: Added Goal model

enum UniksSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [HabitEvent.self, Goal.self]
    }
}

// MARK: - Migration Plan

enum UniksMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [UniksSchemaV1.self, UniksSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: UniksSchemaV1.self,
        toVersion: UniksSchemaV2.self
    )
}
