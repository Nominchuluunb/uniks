//
//  UModelCard.swift
//  uniks
//
//  Model management card showing status, progress, and contextual actions.
//

import SwiftUI

struct UModelCard: View {
    let model: LocalModel
    let status: LocalModelStatus
    let isActive: Bool
    var onDownload: (() -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?
    var onRetry: (() -> Void)?
    var onActivate: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing(.xxxSmall)) {
                    HStack(spacing: .spacing(.xSmall)) {
                        Text(model.name)
                            .font(.uHeadline)
                        if isActive {
                            Text("Active")
                                .font(.uCaption)
                                .foregroundStyle(Color.positive)
                                .padding(.horizontal, .spacing(.xSmall))
                                .padding(.vertical, .spacing(.xxxSmall))
                                .background(Color.positiveSubtle, in: Capsule())
                        }
                    }
                    Text("\(model.family) · \(model.quantization) · ~\(String(format: "%.1f", model.estimatedSizeGB)) GB")
                        .font(.uCaption)
                        .foregroundStyle(Color.secondaryLabel)
                }
                Spacer()
                statusIcon
            }

            Text(model.summary)
                .font(.uFootnote)
                .foregroundStyle(Color.secondaryLabelMuted)

            // Progress
            if case .downloading(let progress) = status {
                VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                    UProgressBar(progress: progress.fractionCompleted)
                    HStack {
                        Text(progress.percentText)
                            .font(.uNumeric)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandBlue)
                        Spacer()
                        Text(progress.bytesDisplayText)
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                }
            }

            // Error message
            if case .failed(let message) = status {
                Text(message)
                    .font(.uCaption)
                    .foregroundStyle(Color.negative)
            }

            // Actions
            HStack(spacing: .spacing(.xSmall)) {
                switch status {
                case .notDownloaded:
                    UButton("Download", style: .primary) { onDownload?() }
                case .queued:
                    UButton("Queued…", style: .secondary, isLoading: true) {}
                case .downloading:
                    UButton("Cancel", style: .secondary) { onCancel?() }
                case .downloaded:
                    if !isActive {
                        UButton("Activate", style: .secondary) { onActivate?() }
                    }
                    UButton("Delete", style: .destructive) { onDelete?() }
                case .failed:
                    UButton("Retry", style: .primary) { onRetry?() }
                }
            }
        }
        .padding(.spacing(.medium))
        .background(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .fill(isActive ? Color.brandBlueBackground : Color.secondaryGroupedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .stroke(isActive ? Color.brandBlueBorder : Color.separator, lineWidth: isActive ? 1.5 : 0.5)
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .downloaded:
            Image(systemName: Icons.success)
                .font(.uBrandTitle2)
                .foregroundStyle(Color.positive)
        case .failed:
            Image(systemName: Icons.failure)
                .font(.uBrandTitle2)
                .foregroundStyle(Color.negative)
        default:
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: .spacing(.medium)) {
        UModelCard(
            model: LocalModel.allModels[0],
            status: .notDownloaded,
            isActive: false,
            onDownload: {}
        )
        UModelCard(
            model: LocalModel.allModels[0],
            status: .downloading(ModelDownloadProgress(
                fractionCompleted: 0.45,
                completedBytes: 276_824_064,
                totalBytes: 629_145_600,
                phase: .downloading
            )),
            isActive: false,
            onCancel: {}
        )
        UModelCard(
            model: LocalModel.allModels[0],
            status: .downloaded(size: 629_145_600),
            isActive: true,
            onDelete: {}
        )
    }
    .padding()
}
