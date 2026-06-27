//
//  ModelDownloadProgress.swift
//  uniks
//
//  Real-time download progress for on-device LLM models.
//

import Foundation

/// The current phase of a model download operation.
enum DownloadPhase: String, Sendable, Equatable {
    case queued
    case downloading
    case verifying
    case loading
}

/// Real-time download progress reported by the model download pipeline.
struct ModelDownloadProgress: Sendable, Equatable {
    let fractionCompleted: Double
    let completedBytes: Int64
    let totalBytes: Int64
    let phase: DownloadPhase

    /// User-facing progress text, e.g. "312 MB / 693 MB".
    var bytesDisplayText: String {
        "\(Self.format(bytes: completedBytes)) / \(Self.format(bytes: totalBytes))"
    }

    /// Percentage as an integer string, e.g. "45%".
    var percentText: String {
        "\(Int(fractionCompleted * 100))%"
    }

    private static func format(bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}
