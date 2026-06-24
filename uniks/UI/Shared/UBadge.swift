//
//  UBadge.swift
//  uniks
//
//  Shared status badge for HabitEvent states.
//

import SwiftUI

struct UBadge: View {
    let state: HabitEventState
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: .spacing(.xxSmall)) {
            Image(systemName: iconName)
                .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            Text(state.displayName)
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

    private var iconName: String {
        switch state {
        case .pending:
            return Icons.pending
        case .parsed:
            return Icons.success
        case .failed:
            return Icons.failure
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .pending:
            return Color.accentColor
        case .parsed:
            return Color.positive
        case .failed:
            return Color.negative
        }
    }
}

private extension HabitEventState {
    var displayName: String { rawValue.capitalized }
}

#Preview {

    VStack(spacing: .spacing(.small)) {
        UBadge(state: .pending)
        UBadge(state: .parsed)
        UBadge(state: .failed)
    }
    .padding()
}
