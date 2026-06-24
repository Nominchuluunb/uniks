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
            Color(nsColor: .windowBackgroundColor)
            
            // Soft blue glow
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 500, height: 500)
                .offset(x: 150, y: -200)
                .blur(radius: 80)
            
            // Soft purple glow
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 600, height: 600)
                .offset(x: -200, y: 150)
                .blur(radius: 90)
            
            // Soft red/pink glow
            Circle()
                .fill(Color.red.opacity(0.08))
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
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Uniks")
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(Color.primaryLabel) +
            Text(" Offline Intelligence")
                .font(.system(.body, design: .rounded).weight(.medium))
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
        To continue, Uniks will start downloading the necessary models \
        for on-device processing. Please ensure you have a stable internet connection.
        """

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.large)) {
            // Hero Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Speak naturally,")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                
                Text("express effectively,")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, Color(red: 0.6, green: 0.4, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("no cap.")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.purple.opacity(0.5))
            }
            .padding(.horizontal, .spacing(.large))
            
            // Subtitle Offline Box
            HStack(spacing: .spacing(.medium)) {
                Image(systemName: "sparkle")
                    .font(.title2)
                    .foregroundStyle(Color.blue)
                    .padding(.spacing(.small))
                    .background(Color.blue.opacity(0.08), in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fully local, on-device processing")
                        .font(.system(.body, design: .rounded).weight(.bold))
                    Text("Offline Intelligence powered by Gemma.")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }
            .padding(.spacing(.medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.12), lineWidth: 1.0)
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
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Color.secondaryLabel.opacity(0.85))
                .padding(.spacing(.medium))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separator.opacity(0.2), lineWidth: 0.5))
                
                Spacer()
                
                // Get Started CTA
                Button {
                    withAnimation {
                        currentPage = 1
                    }
                } label: {
                    Text("Get Started")
                        .font(.uHeadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, .spacing(.xxLarge))
                        .padding(.vertical, .spacing(.medium))
                        .background(Color.blue, in: Capsule())
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                Text("offline AI powered")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                Text("features")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                
                Text(
                    "Download the required Gemma models. By running entirely on your " +
                    "device, these smart yet highly efficient models power everything " +
                    "from dictation to complex text edits while guaranteeing your privacy. " +
                    "There is no cost or cap for using the features enabled by these models."
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
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(Color.blue)
                        
                        Text("Gemma")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing(.medium))
                    .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    
                    Text("What is Gemma?")
                        .font(.uHeadline)
                        .foregroundStyle(Color.primaryLabel)
                    
                    Text(
                        "Gemma is a family of lightweight, state-of-the-art open models " +
                        "built from the same research and technology used to create the " +
                        "Gemini models. These models are sized and fine-tuned to run " +
                        "efficiently on your laptop."
                    )
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.secondaryLabel)
                    .lineSpacing(2)
                }
                .padding(.spacing(.large))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separator.opacity(0.3), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                
                Button(action: onDownload) {
                    Text("Download")
                        .font(.uHeadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, .spacing(.xxLarge))
                        .padding(.vertical, .spacing(.small))
                        .background(Color.blue, in: Capsule())
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                Text("offline AI powered")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                Text("features")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryLabel)
                
                Text(
                    "Download the required Gemma models. By running entirely on your " +
                    "device, these smart yet highly efficient models power everything " +
                    "from dictation to complex text edits while guaranteeing your privacy. " +
                    "There is no cost or cap for using the features enabled by these models."
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
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(Color.blue)
                        
                        Text("Gemma")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing(.medium))
                    .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    
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
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(downloadProgress))
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.uNumeric)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.blue)
                        
                        Spacer()
                        
                        Text(downloadedMBText)
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                    
                    Text("Please keep the application open during the download process.")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Color.secondaryLabel.opacity(0.8))
                }
                .padding(.spacing(.large))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.separator.opacity(0.3), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                
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
