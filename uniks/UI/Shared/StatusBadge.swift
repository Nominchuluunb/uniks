//
//  StatusBadge.swift
//  uniks
//
//  Shared status indicator used across HUD and Dashboard.
//

import SwiftUI

struct StatusBadge: View {
    let state: HabitEventState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(state.displayName)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(foregroundColor)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch state {
        case .pending:
            return "ellipsis.circle"
        case .parsed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .pending:
            return .secondary
        case .parsed:
            return .green
        case .failed:
            return .red
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

private extension HabitEventState {
    var displayName: String { rawValue.capitalized }
}

#Preview {
    VStack(spacing: 8) {
        StatusBadge(state: .pending)
        StatusBadge(state: .parsed)
        StatusBadge(state: .failed)
    }
}
