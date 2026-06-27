//
//  OnboardingSubviews.swift
//  uniks
//
//  Subviews for the Gemma-powered onboarding flow.
//

import SwiftUI

// MARK: - MeshBackground

struct MeshBackground: View {
    var body: some View {
        ZStack {
            Color.groupedBackground
            Circle()
                .fill(Color.brandBlueGlowStrong)
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 500, height: 500)
                .offset(x: 150, y: -200)
                .blur(radius: 80)
            Circle()
                .fill(Color.brandPurpleGlowMedium)
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 600, height: 600)
                .offset(x: -200, y: 150)
                .blur(radius: 90)
            Circle()
                .fill(Color.brandRedGlowSoft)
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 450, height: 450)
                .offset(x: 250, y: 200)
                .blur(radius: 80)
        }
        .ignoresSafeArea()
    }
}

// MARK: - UniksLogoHeader

struct UniksLogoHeader: View {
    var body: some View {
        HStack(spacing: .spacing(.small)) {
            Image(systemName: Icons.sparkles)
                .font(.uBrandTitle2)
                .foregroundStyle(Gradients.logo)
            Text("Uniks")
                .font(.uBrandBodyBold)
                .foregroundStyle(Color.primaryLabel) +
            Text(" Offline Intelligence")
                .font(.uBrandBodyMedium)
                .foregroundStyle(Color.secondaryLabel)
        }
    }
}

// MARK: - WelcomeStage

struct WelcomeStage: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.large)) {
            // Hero
            VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                Text("Speak naturally,")
                    .font(.uHero)
                    .foregroundStyle(Color.primaryLabel)
                Text("express effectively,")
                    .font(.uHero)
                    .foregroundStyle(Gradients.hero)
                Text("no cap.")
                    .font(.uHero)
                    .foregroundStyle(Color.brandPurpleMuted)
            }

            // Offline Box
            HStack(spacing: .spacing(.medium)) {
                Image(systemName: Icons.sparkle)
                    .font(.uBrandTitle2)
                    .foregroundStyle(Color.brandBlue)
                    .padding(.spacing(.small))
                    .background(Color.brandBlueGlowSoft, in: Circle())
                VStack(alignment: .leading, spacing: .spacing(.xxxSmall)) {
                    Text("Fully local, on-device processing")
                        .font(.uBrandBodyBold)
                    Text("Offline Intelligence powered by Gemma.")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }
            .padding(.spacing(.medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.brandBlueBackground)
            .overlay(
                RoundedRectangle(cornerRadius: .radius(.large))
                    .stroke(Color.brandBlueBorder, lineWidth: 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: .radius(.large)))

            // Terms + CTA
            HStack(alignment: .bottom, spacing: .spacing(.large)) {
                VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                    Text(
                        "All parsing runs entirely on your device. " +
                        "Your habits and AI parsing logs never leave your hardware."
                    )
                    Text(
                        "Zero telemetry, zero analytics. " +
                        "No outbound network requests for data logging."
                    )
                    Text(
                        "To continue, Uniks will download Gemma models from Hugging Face. " +
                        "Ensure a stable internet connection. No personal data is sent."
                    )
                }
                .font(.uMicro)
                .foregroundStyle(Color.secondaryLabelMuted)
                .padding(.spacing(.medium))
                .background(
                    RoundedRectangle(cornerRadius: .radius(.large))
                        .fill(Color.glassBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .radius(.large))
                        .stroke(Color.separatorVeryFaint, lineWidth: 0.5)
                )

                Spacer()

                UButton("Get Started", style: .primary) {
                    withAnimation { currentPage = 1 }
                }
            }
        }
    }
}

// MARK: - SetupStage

struct SetupStage: View {
    @Binding var currentPage: Int
    let onDownload: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: .spacing(.xxLarge)) {
            // Left description
            VStack(alignment: .leading, spacing: .spacing(.medium)) {
                Text("Enable private,")
                    .font(.uHeroSmall)
                Text("offline AI powered")
                    .font(.uHeroSmall)
                Text("features")
                    .font(.uHeroSmall)
                Text(
                    "Download the Gemma model from Hugging Face. Running entirely on " +
                    "your device, this efficient model powers parsing while guaranteeing " +
                    "your privacy. No cost or cap."
                )
                .font(.uCallout)
                .foregroundStyle(Color.secondaryLabel)
                .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Gemma card
            VStack(alignment: .trailing, spacing: .spacing(.large)) {
                gemmaInfoCard
                UButton("Download", style: .primary, action: onDownload)
            }
            // swiftlint:disable:next hardcoded_frame_size
            .frame(width: 320)
        }
    }

    private var gemmaInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacing(.medium)) {
            VStack(alignment: .center, spacing: .spacing(.xSmall)) {
                Image(systemName: Icons.sparkles)
                    .font(.uTitle)
                    .foregroundStyle(Color.brandBlue)
                Text("Gemma")
                    .font(.uBrandTitle)
                    .foregroundStyle(Color.brandBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing(.medium))
            .background(Color.brandBlueBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))

            Text("What is Gemma?")
                .font(.uHeadline)

            Text(
                "Gemma is a family of lightweight, state-of-the-art open models " +
                "by Google. Sized and fine-tuned to run efficiently on Apple Silicon."
            )
            .font(.uCaption2)
            .foregroundStyle(Color.secondaryLabel)
            .lineSpacing(2)
        }
        .padding(.spacing(.large))
        .background(RoundedRectangle(cornerRadius: .radius(.large)).fill(Color.elevatedBackground))
        .overlay(RoundedRectangle(cornerRadius: .radius(.large)).stroke(Color.separatorFaint, lineWidth: 0.5))
        .shadow(color: Color.shadowSubtle, radius: 8, x: 0, y: 4)
    }
}

// MARK: - ProgressStage

struct ProgressStage: View {
    let progress: ModelDownloadProgress?
    let status: LocalModelStatus
    let error: String?
    let onRetry: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: .spacing(.xxLarge)) {
            // Left description
            VStack(alignment: .leading, spacing: .spacing(.medium)) {
                Text("Enable private,")
                    .font(.uHeroSmall)
                Text("offline AI powered")
                    .font(.uHeroSmall)
                Text("features")
                    .font(.uHeroSmall)
                Text(
                    "Downloading Gemma from Hugging Face. " +
                    "This runs entirely on your device for guaranteed privacy."
                )
                .font(.uCallout)
                .foregroundStyle(Color.secondaryLabel)
                .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right progress card
            VStack(alignment: .trailing, spacing: .spacing(.large)) {
                downloadCard
                actionButtons
            }
            // swiftlint:disable:next hardcoded_frame_size
            .frame(width: 320)
        }
    }

    private var downloadCard: some View {
        VStack(alignment: .leading, spacing: .spacing(.medium)) {
            VStack(alignment: .center, spacing: .spacing(.xSmall)) {
                Image(systemName: Icons.sparkles)
                    .font(.uTitle)
                    .foregroundStyle(Color.brandBlue)
                Text("Gemma")
                    .font(.uBrandTitle)
                    .foregroundStyle(Color.brandBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing(.medium))
            .background(Color.brandBlueBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))

            if let error {
                Text(error)
                    .font(.uCaption)
                    .foregroundStyle(Color.negative)
            } else {
                Text("Downloading models…")
                    .font(.uHeadline)

                UProgressBar(progress: progress?.fractionCompleted ?? 0)

                HStack {
                    Text(progress?.percentText ?? "0%")
                        .font(.uNumeric)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandBlue)
                    Spacer()
                    Text(progress?.bytesDisplayText ?? "")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel)
                }

                Text("Please keep the application open during download.")
                    .font(.uMicro)
                    .foregroundStyle(Color.secondaryLabelSubtle)
            }
        }
        .padding(.spacing(.large))
        .background(RoundedRectangle(cornerRadius: .radius(.large)).fill(Color.elevatedBackground))
        .overlay(RoundedRectangle(cornerRadius: .radius(.large)).stroke(Color.separatorFaint, lineWidth: 0.5))
        .shadow(color: Color.shadowSubtle, radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if error != nil {
            HStack(spacing: .spacing(.xSmall)) {
                UButton("Retry", style: .primary, action: onRetry)
                UButton("Skip for now", style: .secondary, action: onSkip)
            }
        } else {
            UButton("Downloading…", style: .secondary, isLoading: true) {}
        }
    }
}
