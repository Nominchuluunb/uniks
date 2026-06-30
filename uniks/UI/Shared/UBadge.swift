//
//  UBadge.swift
//  uniks
//
//  Shared status badge for HabitEvent states with confidence gradation.
//

import SwiftUI

struct UBadge: View {
    let state: HabitEventState
    var confidence: Double?
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: .spacing(.xxSmall)) {
            Image(systemName: iconName)
                .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            Text(displayText)
        }
        .font(.uCaption)
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, .spacing(.xSmall))
        .padding(.vertical, .spacing(.xxSmall))
        .background(
            Capsule()
                .fill(foregroundColor.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(foregroundColor.opacity(0.18), lineWidth: 0.5)
        )
        .opacity(state == .pending && isAnimating ? 0.6 : 1.0)
        .onAppear {
            triggerAnimation()
        }
        .onChange(of: state) { _, _ in
            triggerAnimation()
        }
    }

    private func triggerAnimation() {
        if state == .pending {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        } else {
            isAnimating = false
        }
    }

    private var displayText: String {
        switch state {
        case .heuristicParsed:
            return "Quick"
        case .parsed:
            if let conf = confidence {
                let level = ParseConfidence(confidence: conf)
                return level.displayName
            }
            return "Parsed"
        case .enriched:
            return "Enriched"
        default:
            return state.rawValue.capitalized
        }
    }

    private var iconName: String {
        switch state {
        case .pending:
            return Icons.pending
        case .heuristicParsed:
            return Icons.bolt
        case .parsed:
            if let conf = confidence, ParseConfidence(confidence: conf) == .low {
                return Icons.failure
            }
            return Icons.success
        case .enriched:
            return Icons.success
        case .failed:
            return Icons.failure
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .pending:
            return Color.accent
        case .heuristicParsed:
            return Color.warning
        case .parsed:
            if let conf = confidence {
                return ParseConfidence(confidence: conf).color
            }
            return Color.positive
        case .enriched:
            return Color.positive
        case .failed:
            return Color.negative
        }
    }
}

#Preview {
    VStack(spacing: .spacing(.small)) {
        UBadge(state: .pending)
        UBadge(state: .heuristicParsed)
        UBadge(state: .parsed, confidence: 0.9)
        UBadge(state: .parsed, confidence: 0.6)
        UBadge(state: .parsed, confidence: 0.3)
        UBadge(state: .enriched)
        UBadge(state: .failed)
    }
    .padding()
}
