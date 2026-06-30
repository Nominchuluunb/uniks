//
//  ParseConfidence.swift
//  uniks
//
//  Confidence level classification for parsed results.
//

import SwiftUI

/// Categorizes a numeric confidence score into actionable levels.
enum ParseConfidence: Sendable, Equatable {
    case high
    case medium
    case low

    /// Creates a confidence level from a numeric score.
    /// - Parameter confidence: A value between 0.0 and 1.0.
    init(confidence: Double) {
        if confidence > 0.8 {
            self = .high
        } else if confidence > 0.5 {
            self = .medium
        } else {
            self = .low
        }
    }

    /// User-facing display name.
    var displayName: String {
        switch self {
        case .high: return "Parsed"
        case .medium: return "Review?"
        case .low: return "Low"
        }
    }

    /// Semantic color for the confidence level.
    var color: Color {
        switch self {
        case .high: return Color.positive
        case .medium: return Color.warning
        case .low: return Color.negative
        }
    }
}
