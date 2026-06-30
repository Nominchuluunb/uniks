//
//  UserCorrection.swift
//  uniks
//
//  Stores user corrections to improve future parsing accuracy.
//

import Foundation
import SwiftData

/// Records a user's correction of a parsed result for feedback loop learning.
/// When a user edits a parsed event, the original input and corrected result
/// are stored so future similar inputs can be auto-corrected.
@Model
final class UserCorrection {
    @Attribute(.unique) var id: UUID
    var originalInput: String
    var correctedPayloadJSON: String
    var createdAt: Date

    init(originalInput: String, correctedPayload: HabitParseResult) {
        self.id = UUID()
        self.originalInput = originalInput
        self.correctedPayloadJSON = (try? correctedPayload.toJSON()) ?? "{}"
        self.createdAt = Date()
    }

    /// Decoded corrected payload.
    func correctedPayload() -> HabitParseResult? {
        try? HabitParseResult.fromJSON(correctedPayloadJSON)
    }
}
