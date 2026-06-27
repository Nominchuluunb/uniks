//
//  OnboardingView.swift
//  uniks
//
//  First-launch onboarding explaining the capture flow and privacy promise.
//

import SwiftUI

@MainActor
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var downloadProgress = 0.0
    @State private var isDownloading = false
    @State private var modelManager = LocalModelManager()

    static let completedKey = "uniks.hasCompletedOnboarding"

    var body: some View {
        ZStack {
            MeshBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header (Logo or Back button)
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                if currentPage == 2 && isDownloading {
                                    isDownloading = false
                                    downloadProgress = 0.0
                                }
                                currentPage -= 1
                            }
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
                        // Slide progress indicator
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
                
                Spacer()
                
                // Content Views
                Group {
                    switch currentPage {
                    case 0:
                        WelcomeStage(currentPage: $currentPage)
                    case 1:
                        SetupStage(currentPage: $currentPage, onDownload: {
                            withAnimation {
                                currentPage = 2
                                startDownloadProgress()
                            }
                        })
                    case 2:
                        ProgressStage(
                            downloadProgress: downloadProgress,
                            downloadedMBText: downloadedMBText
                        )
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                
                Spacer()
            }
        }
        // swiftlint:disable:next hardcoded_frame_size
        .frame(width: 720, height: 520)
    }
    
    // MARK: - Simulated Download Progress
    
    private var downloadedMBText: String {
        let current = 2735.2 * downloadProgress
        return String(format: "%.1f MB / 2735.2 MB", current)
    }
    
    private func startDownloadProgress() {
        isDownloading = true
        downloadProgress = 0.0

        // Start actual local model manager download in the background
        Task {
            if let model = LocalModel.allModels.first {
                await modelManager.download(model)
            }
        }

        // Animate simulated progress using structured concurrency
        Task {
            while isDownloading && downloadProgress < 1.0 {
                try? await Task.sleep(for: .milliseconds(80))
                downloadProgress += 0.01
            }
            isDownloading = false
            UserDefaults.standard.set(true, forKey: Self.completedKey)
            isPresented = false
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
