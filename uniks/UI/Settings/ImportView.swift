//
//  ImportView.swift
//  uniks
//
//  File picker and import UI for JSON/CSV data import.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ImportView: View {
    let importService: ImportService
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacing(.large)) {
                // Icon
                Image(systemName: "square.and.arrow.down")
                    .font(.uExtraLargeIcon)
                    .foregroundStyle(Gradients.brand)
                    .padding(.top, .spacing(.xxLarge))

                // Title
                VStack(spacing: .spacing(.small)) {
                    Text("Import Events")
                        .font(.uHeadline)
                    Text("Import events from a JSON or CSV file. Duplicates will be automatically skipped.")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .spacing(.large))

                // Supported formats
                VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                    formatRow(icon: "doc.text", title: "JSON", subtitle: "Uniks export format (recommended)")
                    formatRow(icon: "tablecells", title: "CSV", subtitle: "Comma-separated with headers")
                }
                .padding(.spacing(.medium))
                .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
                .padding(.horizontal, .spacing(.medium))

                Spacer()

                // Result
                if let result = importResult {
                    VStack(spacing: .spacing(.small)) {
                        HStack(spacing: .spacing(.medium)) {
                            resultStat(value: "\(result.imported)", label: "Imported", color: .positive)
                            resultStat(value: "\(result.skipped)", label: "Skipped", color: .warning)
                            if result.failed > 0 {
                                resultStat(value: "\(result.failed)", label: "Failed", color: .negative)
                            }
                        }
                    }
                    .padding(.spacing(.medium))
                    .background(Color.positiveSubtle, in: RoundedRectangle(cornerRadius: .radius(.medium)))
                    .padding(.horizontal, .spacing(.medium))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.uCallout)
                        .foregroundStyle(Color.negative)
                        .padding(.horizontal, .spacing(.medium))
                }

                // Import button
                UButton(
                    isImporting ? "Importing..." : "Choose File",
                    style: .primary,
                    isLoading: isImporting
                ) {
                    isShowingFilePicker = true
                }
                .disabled(isImporting)
                .padding(.horizontal, .spacing(.medium))
                .padding(.bottom, .spacing(.large))
            }
            .navigationTitle("Import")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.json, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                Task { await handleFileSelection(result) }
            }
        }
    }

    // MARK: - Helpers

    private func formatRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: .spacing(.small)) {
            Image(systemName: icon)
                .font(.uBody)
                .foregroundStyle(Color.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: .spacing(.xxxSmall)) {
                Text(title)
                    .font(.uBody)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.uCaption2)
                    .foregroundStyle(Color.secondaryLabel)
            }
            Spacer()
        }
        .padding(.vertical, .spacing(.xxSmall))
    }

    private func resultStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: .spacing(.xxxSmall)) {
            Text(value)
                .font(.uHeadline)
                .foregroundStyle(color)
            Text(label)
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        errorMessage = nil
        importResult = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            isImporting = true
            defer { isImporting = false }

            do {
                let data = try Data(contentsOf: url)
                let isJSON = url.pathExtension.lowercased() == "json"

                if isJSON {
                    importResult = try await importService.importJSON(data)
                } else {
                    importResult = try await importService.importCSV(data)
                }
            } catch {
                errorMessage = "Import failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
}
