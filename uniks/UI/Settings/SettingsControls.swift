//
//  SettingsControls.swift
//  uniks
//
//  Shared controls used inside SettingsView.
//

import SwiftUI

struct LocalModelRow: View {
    let model: LocalModel
    let status: LocalModelStatus
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                    Text(model.name)
                        .font(.uBody)
                        .fontWeight(.semibold)
                    Text(status.displayText)
                        .font(.uCaption)
                        .foregroundStyle(Color.secondaryLabel)
                }

                Spacer()

                switch status {
                case .notDownloaded:
                    Button {
                        onDownload()
                    } label: {
                        Text("Download")
                            .font(.uCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.onAccent)
                            .padding(.horizontal, .spacing(.medium))
                            .padding(.vertical, .spacing(.xxSmall))
                            .background(Gradients.brand, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .interactiveScale()
                case .downloading:
                    EmptyView()
                case .downloaded:
                    Image(systemName: Icons.success)
                        .font(.uBrandTitle2)
                        .foregroundStyle(Color.positive)
                }
            }

            if case .downloading = status {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Color.accent)
                    .padding(.top, .spacing(.xxSmall))
            }
        }
        .padding(.vertical, .spacing(.xxSmall))
    }
}
