//
//  ShareCardView.swift
//  uniks
//
//  Generates a beautiful shareable image card from a parsed event.
//

import SwiftUI

/// A rendered card view for sharing events as images.
struct ShareCardView: View {
    let event: HabitEvent
    let size: ShareCardSize

    enum ShareCardSize {
        case square      // 1080x1080
        case story       // 1080x1920

        var width: CGFloat { 1080 }
        var height: CGFloat {
            switch self {
            case .square: return 1080
            case .story: return 1920
            }
        }

        var scale: CGFloat { 0.35 } // Render scale for preview
    }

    var body: some View {
        VStack(spacing: .spacing(.large)) {
            Spacer()

            // Logo header
            HStack(spacing: .spacing(.small)) {
                Image(systemName: Icons.sparkles)
                    .font(.uBrandTitle2)
                    .foregroundStyle(Color.onAccent)
                Text("Uniks")
                    .font(.uBrandBodyBold)
                    .foregroundStyle(Color.onAccent)
            }
            .opacity(0.8)

            Spacer()

            // Main content
            VStack(spacing: .spacing(.medium)) {
                // Event text
                Text(event.rawInput)
                    .font(.uHero)
                    .foregroundStyle(Color.onAccent)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)

                // Parsed chips
                if let payload = event.parsedPayload() {
                    HStack(spacing: .spacing(.small)) {
                        if let category = payload.category {
                            cardChip(text: category, icon: Icons.categorySymbol(for: category))
                        }
                        if let value = payload.value, let unit = payload.unit {
                            cardChip(text: "\(Int(value)) \(unit)", icon: nil)
                        }
                    }
                }

                // Date
                Text(event.createdAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.uCallout)
                    .foregroundStyle(Color.onAccent.opacity(0.7))
            }
            .padding(.spacing(.xxLarge))

            Spacer()

            // Footer
            Text("Logged with Uniks")
                .font(.uMicro)
                .foregroundStyle(Color.onAccent.opacity(0.5))
                .padding(.bottom, .spacing(.large))
        }
        .frame(width: size.width * size.scale, height: size.height * size.scale)
        .background(
            LinearGradient(
                colors: [Color.brandBlue, Color.brandPurple, Color.brandOrange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: .radius(.large)))
    }

    private func cardChip(text: String, icon: String?) -> some View {
        HStack(spacing: .spacing(.xxSmall)) {
            if let icon {
                Image(systemName: icon)
                    .font(.uCaption)
            }
            Text(text)
                .font(.uCaption)
                .fontWeight(.medium)
        }
        .foregroundStyle(Color.onAccent)
        .padding(.horizontal, .spacing(.small))
        .padding(.vertical, .spacing(.xxSmall))
        .background(Color.onAccent.opacity(0.2), in: Capsule())
    }
}

// MARK: - Image Rendering

extension ShareCardView {
    /// Renders the card as a platform image.
    @MainActor
    static func renderImage(
        event: HabitEvent,
        size: ShareCardSize = .square
    ) -> CGImage? {
        let view = ShareCardView(event: event, size: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // Retina
        return renderer.cgImage
    }
}

#Preview {
    ShareCardView(
        event: {
            let e = HabitEvent(rawInput: "Ran 5km in 28min, felt amazing!")
            e.setParsedPayload(HabitParseResult(
                category: "Fitness", value: 5, unit: "km",
                tags: ["morning", "outdoor"], confidence: 0.95
            ))
            return e
        }(),
        size: .square
    )
    .padding()
}
