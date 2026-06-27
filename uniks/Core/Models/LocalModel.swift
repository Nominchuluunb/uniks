//
//  LocalModel.swift
//  uniks
//
//  Represents a downloadable on-device LLM model from the Gemma family.
//

import Foundation

/// The current download/activation status of a local model.
enum LocalModelStatus: Sendable {
    case notDownloaded
    case queued
    case downloading(ModelDownloadProgress)
    case downloaded(size: UInt64)
    case failed(message: String)
}

extension LocalModelStatus: Equatable {
    static func == (lhs: LocalModelStatus, rhs: LocalModelStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded), (.queued, .queued):
            return true
        case (.downloading(let a), .downloading(let b)):
            return a == b
        case (.downloaded(let a), .downloaded(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

extension LocalModelStatus {
    /// A user-facing description of the status.
    var displayText: String {
        switch self {
        case .notDownloaded:
            return "Not downloaded"
        case .queued:
            return "Queued…"
        case .downloading(let progress):
            return "Downloading \(progress.percentText) · \(progress.bytesDisplayText)"
        case .downloaded(let size):
            return "Downloaded · \(Self.formattedSize(size))"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }

    /// Whether the model is ready for use.
    var isReady: Bool {
        if case .downloaded = self { return true }
        return false
    }

    private static func formattedSize(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb < 0.1 {
            return String(format: "%.0f MB", Double(bytes) / 1_048_576)
        }
        return String(format: "%.1f GB", gb)
    }
}

/// A local LLM model that can be downloaded for on-device inference.
struct LocalModel: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let family: String
    let quantization: String
    let summary: String
    let estimatedSizeGB: Double
    let isDefault: Bool
    let registryKey: String?

    /// The Hugging Face cache folder name for this model.
    var cacheFolderName: String {
        let sanitized = id.replacingOccurrences(of: "/", with: "--")
        return "models--\(sanitized)"
    }
}

extension LocalModel {
    /// Built-in Gemma models available for download.
    static let allModels: [LocalModel] = [
        LocalModel(
            id: "mlx-community/gemma-3-1B-it-qat-4bit",
            name: "Gemma 3 1B",
            family: "Gemma",
            quantization: "4-bit QAT",
            summary: "Fastest, smallest Gemma — ideal for quick parsing on any Apple Silicon device.",
            estimatedSizeGB: 0.6,
            isDefault: true,
            registryKey: "gemma3_1B_qat_4bit"
        ),
        LocalModel(
            id: "mlx-community/gemma-2-2b-it-4bit",
            name: "Gemma 2 2B",
            family: "Gemma",
            quantization: "4-bit",
            summary: "Higher quality extraction with richer context understanding.",
            estimatedSizeGB: 1.5,
            isDefault: false,
            registryKey: nil
        )
    ]

    /// The default model from the catalog.
    static var defaultModel: LocalModel {
        // swiftlint:disable:next force_unwrapping
        allModels.first(where: \.isDefault)!
    }
}
