//
//  LocalModel.swift
//  uniks
//
//  Represents a downloadable on-device LLM model.
//

import Foundation

/// The current download status of a local model.
enum LocalModelStatus: Equatable, Sendable {
    case notDownloaded
    case downloading
    case downloaded(size: UInt64)
}

/// A local LLM model that can be downloaded for on-device inference.
struct LocalModel: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let estimatedSizeGB: Double

    /// The Hugging Face cache folder name for this model.
    var cacheFolderName: String {
        let sanitized = id.replacingOccurrences(of: "/", with: "--")
        return "models--\(sanitized)"
    }
}

extension LocalModel {
    /// Built-in models available for download.
    static let allModels: [LocalModel] = [
        LocalModel(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            name: "Llama 3.2 1B Instruct",
            estimatedSizeGB: 0.7
        ),
        LocalModel(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            name: "Llama 3.2 3B Instruct",
            estimatedSizeGB: 1.9
        )
    ]
}
