//
//  OnboardingSubviews.swift
//  uniks
//
//  Subviews for the Google AI Edge Eloquent onboarding flow.
//

import SwiftUI

struct MeshBackground: View {
    var body: some View {
        ZStack {
            Color.groupedBackground

            // Soft blue glow
            Circle()
                .fill(Color.brandBlueGlowStrong)
                .frame(width: 500, height: 500)
                .offset(x: 150, y: -200)
                .blur(radius: 80)

            // Soft purple glow
            Circle()
                .fill(Color.brandPurpleGlowMedium)
                .frame(width: 600, height: 600)
                .offset(x: -200, y: 150)
                .blur(radius: 90)

            // Soft red/pink glow
            Circle()
                .fill(Color.brandRedGlowSoft)
                .frame(width: 450, height: 450)
                .offset(x: 250, y: 200)
                .blur(radius: 80)
        }
        .ignoresSafeArea()
    }
}

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

struct WelcomeStage: View {
    @Binding var currentPage: Int
    
    private let termsText = """
        All parsing and processing is performed entirely on your device. \
        Your personal event history, habits, and AI parsing logs are processed \
        and stored exclusively on your physical hardware.
        """
    
    private let metricsText = """
        Uniks collects zero telemetry, zero analytics, and zero personal \
        information. No outbound network requests are made for data logging, \
        ensuring complete local data privacy.
        """
        
    private let stableText = """
        To continue, Uniks will download the necessary models from Hugging Face \
        for on-device processing. Please ensure you have a stable internet connection. \
        No personal data is sent to Hugging Face or any other service.
        """

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.large)) {
            // Hero Title
            VStack(alignment: .leading, spacing: 4) {
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
            .padding(.horizontal, .spacing(.large))
            
            // Subtitle Offline Box
            HStack(spacing: .spacing(.medium)) {
                Image(systemName: Icons.sparkle)
                    .font(.uBrandTitle2)
                    .foregroundStyle(Color.brandBlue)
                    .padding(.spacing(.small))
                    .background(Color.brandBlueGlowSoft, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
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
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandBlueBorder, lineWidth: 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, .spacing(.large))
            
            // Terms Card & Bottom Button
            HStack(alignment: .bottom, spacing: .spacing(.large)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(termsText)
                    Text(metricsText)
                    Text(stableText)
                }
                .font(.uMicro)
                .foregroundStyle(Color.secondaryLabelMuted)
                .padding(.spacing(.medium))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.glassBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separatorVeryFaint, lineWidth: 0.5))
                
                Spacer()
                
                // Get Started CTA
                Button {
                    withAnimation {
                        currentPage = 1
                    }
                } label: {
                    Text("Get Started")
                        .font(.uHeadline)
                        .foregroundStyle(Color.onAccent)
                        .padding(.horizontal, .spacing(.xxLarge))
                        .padding(.vertical, .spacing(.medium))
                        .background(Color.brandBlue, in: Capsule())
                        .shadow(color: Color.brandBlueShadow, radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .interactiveScale()
            }
            .padding(.horizontal, .spacing(.large))
        }
    }
}

struct SetupStage: View {
    @Binding var currentPage: Int
    let onDownload: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: .spacing(.xxLarge)) {
            // Left Specs Column
            VStack(alignment: .leading, spacing: .spacing(.medium)) {
                Text("Enable private,")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                Text("offline AI powered")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                Text("features")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                
                Text(
                    "Download the required Gemma models from Hugging Face. By running " +
                    "entirely on your device, these smart yet highly efficient models power " +
                    "parsing while guaranteeing your privacy. No personal data is sent to " +
                    "Hugging Face. There is no cost or cap for using the features enabled by " +
                    "these models."
                )
                .font(.uCallout)
                .foregroundStyle(Color.secondaryLabel)
                .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Gemma Details Card
            VStack(alignment: .trailing, spacing: .spacing(.large)) {
                VStack(alignment: .leading, spacing: .spacing(.medium)) {
                    // Gemma Logo Header
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
                    .background(Color.brandBlueBackground, in: RoundedRectangle(cornerRadius: 12))

                    Text("What is Gemma?")
                        .font(.uHeadline)
                        .foregroundStyle(Color.primaryLabel)

                    Text(
                        "Gemma is a family of lightweight, state-of-the-art open models " +
                        "built from the same research and technology used to create the " +
                        "Gemini models. These models are sized and fine-tuned to run " +
                        "efficiently on your laptop."
                    )
                    .font(.uCaption2)
                    .foregroundStyle(Color.secondaryLabel)
                    .lineSpacing(2)
                }
                .padding(.spacing(.large))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.elevatedBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separatorFaint, lineWidth: 0.5))
                .shadow(color: Color.shadowSubtle, radius: 8, x: 0, y: 4)

                Button(action: onDownload) {
                    Text("Download")
                        .font(.uHeadline)
                        .foregroundStyle(Color.onAccent)
                        .padding(.horizontal, .spacing(.xxLarge))
                        .padding(.vertical, .spacing(.small))
                        .background(Color.brandBlue, in: Capsule())
                        .shadow(color: Color.brandBlueShadowSoft, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .interactiveScale()
            }
            .frame(width: 320)
        }
        .padding(.horizontal, .spacing(.large))
    }
}

struct ProgressStage: View {
    let downloadProgress: Double
    let downloadedMBText: String
    
    var body: some View {
        HStack(alignment: .center, spacing: .spacing(.xxLarge)) {
            // Left Specs Column (same as Stage 2)
            VStack(alignment: .leading, spacing: .spacing(.medium)) {
                Text("Enable private,")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                Text("offline AI powered")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                Text("features")
                    .font(.uHeroSmall)
                    .foregroundStyle(Color.primaryLabel)
                
                Text(
                    "Downloading the required Gemma models from Hugging Face. By running " +
                    "entirely on your device, these models power parsing while guaranteeing " +
                    "your privacy. No personal data is sent to Hugging Face."
                )
                .font(.uCallout)
                .foregroundStyle(Color.secondaryLabel)
                .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right Download Progress Card
            VStack(alignment: .trailing, spacing: .spacing(.large)) {
                VStack(alignment: .leading, spacing: .spacing(.medium)) {
                    // Gemma Logo Header
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
                    .background(Color.brandBlueBackground, in: RoundedRectangle(cornerRadius: 12))

                    Text("Downloading models...")
                        .font(.uHeadline)
                        .foregroundStyle(Color.primaryLabel)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.tertiaryGroupedBackground)
                                .frame(width: geo.size.width)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brandBlue)
                                .frame(width: geo.size.width * CGFloat(downloadProgress))
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.uNumeric)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandBlue)

                        Spacer()

                        Text(downloadedMBText)
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                    }

                    Text("Please keep the application open during the download process.")
                        .font(.uMicro)
                        .foregroundStyle(Color.secondaryLabelSubtle)
                }
                .padding(.spacing(.large))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.elevatedBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separatorFaint, lineWidth: 0.5))
                .shadow(color: Color.shadowSubtle, radius: 8, x: 0, y: 4)
                
                Button {
                    // Disabled during download
                } label: {
                    Text("Downloading models...")
                        .font(.uHeadline)
                        .foregroundStyle(Color.secondaryLabel)
                        .padding(.horizontal, .spacing(.large))
                        .padding(.vertical, .spacing(.small))
                        .background(Color.tertiaryGroupedBackground, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            .frame(width: 320)
        }
        .padding(.horizontal, .spacing(.large))
    }
}
