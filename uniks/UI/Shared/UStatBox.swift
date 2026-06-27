//
//  UStatBox.swift
//  uniks
//
//  Hero stat card for dashboard metrics.
//

import SwiftUI

struct UStatBox: View {
    let icon: String
    let value: String
    let label: String
    var trend: Trend?
    var tint: Color = .accent

    enum Trend {
        case up
        case down
        case neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
            HStack(spacing: .spacing(.xxSmall)) {
                Image(systemName: icon)
                    .font(.uCaption)
                    .foregroundStyle(tint)
                if let trend {
                    Image(systemName: trendIcon(trend))
                        .font(.uCaption2)
                        .foregroundStyle(trendColor(trend))
                }
            }
            Text(value)
                .font(.uHeadline)
                .foregroundStyle(Color.primaryLabel)
            Text(label)
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing(.medium))
        .background(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .fill(tint.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .stroke(tint.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func trendIcon(_ trend: Trend) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .up: return .positive
        case .down: return .negative
        case .neutral: return .secondaryLabel
        }
    }
}

#Preview {
    HStack(spacing: .spacing(.medium)) {
        UStatBox(icon: "calendar", value: "142", label: "Total Events", trend: .up)
        UStatBox(icon: "flame.fill", value: "7 days", label: "Current Streak", trend: .up, tint: .warning)
        UStatBox(icon: "star.fill", value: "Fitness", label: "Top Category", tint: .brandPurple)
    }
    .padding()
}
