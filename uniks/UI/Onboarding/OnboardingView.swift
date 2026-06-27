//
//  OnboardingView.swift
//  uniks
//
//  First-launch onboarding with real Gemma model download.
//

import SwiftUI

@MainActor
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var modelManager = LocalModelManager()
    @State private var downloadProgress: ModelDownloadProgress?
    @State private var downloadStatus: LocalModelStatus = .notDownloaded
    @State private var downloadError: String?

    static let completedKey = "uniks.hasCompletedOnboarding"

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(alignment: .leading, spacing: 0) {
                headerBar
                Spacer()
                content
                Spacer()
            }
        }
        // swiftlint:disable:next hardcoded_frame_size
        .frame(width: 720, height: 520)
        .task { await checkIfAlreadyDownloaded() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    withAnimation { goBack() }
                } label: {
                    HStack(spacing: .spacing(.xSmall)) {
                        Image(systemName: Icons.chevronLeft)
                        Text("Back")
                    }
                    .font(.uCallout)
                    .foregroundStyle(Color.secondaryLabel)
                }
                .buttonStyle(.plain)
                .interactiveScale()
            } else {
                UniksLogoHeader()
            }

            Spacer()

            if currentPage > 0 {
                HStack(spacing: .spacing(.xxSmall)) {
                    Capsule()
                        .fill(currentPage == 1 ? Color.accent : Color.secondaryLabelFaint)
                        .frame(width: currentPage == 1 ? 24 : 8, height: 6)
                    Capsule()
                        .fill(currentPage == 2 ? Color.accent : Color.secondaryLabelFaint)
                        .frame(width: currentPage == 2 ? 24 : 8, height: 6)
                }
            }
        }
        .padding(.horizontal, .spacing(.large))
        .padding(.top, .spacing(.large))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        Group {
            switch currentPage {
            case 0:
                WelcomeStage(currentPage: $currentPage)
            case 1:
                SetupStage(currentPage: $currentPage, onDownload: { startRealDownload() })
            case 2:
                ProgressStage(
                    progress: downloadProgress,
                    status: downloadStatus,
                    error: downloadError,
                    onRetry: { startRealDownload() },
                    onSkip: { completeOnboarding(skipped: true) }
                )
            default:
                EmptyView()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
        .padding(.horizontal, .spacing(.large))
    }

    // MARK: - Logic

    private func goBack() {
        if currentPage == 2 {
            Task { await modelManager.cancelDownload(LocalModel.defaultModel) }
            downloadProgress = nil
            downloadError = nil
            downloadStatus = .notDownloaded
        }
        currentPage -= 1
    }

    private func checkIfAlreadyDownloaded() async {
        await modelManager.refreshStatuses()
        let status = await modelManager.statuses[LocalModel.defaultModel.id]
        if case .downloaded = status {
            // Already downloaded — skip to completion
            completeOnboarding(skipped: false)
        }
    }

    private func startRealDownload() {
        withAnimation { currentPage = 2 }
        downloadError = nil
        downloadStatus = .queued

        Task {
            let stream = await modelManager.download(LocalModel.defaultModel)
            for await progress in stream {
                downloadProgress = progress
                downloadStatus = .downloading(progress)
            }
            // Stream finished — check final status
            let finalStatus = await modelManager.statuses[LocalModel.defaultModel.id]
            downloadStatus = finalStatus ?? .notDownloaded
            if case .downloaded = finalStatus {
                completeOnboarding(skipped: false)
            } else if case .failed(let msg) = finalStatus {
                downloadError = msg
            }
        }
    }

    private func completeOnboarding(skipped: Bool) {
        if skipped {
            // Set engine to mock so the user isn't stuck without a parser
            EnginePreference.mock.save()
        }
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        isPresented = false
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
