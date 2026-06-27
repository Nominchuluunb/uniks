//
//  UEngineStatusBadge.swift
//  uniks
//
//  Compact badge showing active model + live engine state.
//

import SwiftUI

/// Compact engine status indicator for use in toolbars, sidebars, and HUD.
struct UEngineStatusBadge: View {
    let modelName: String
    let status: EngineStatusState

    enum EngineStatusState: Equatable {
        case ready
        case downloading(percent: Int)
        case loading
        case offline
        case mock
    }

    var body: some View {
        HStack(spacing: .spacing(.xxSmall)) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            Text(displayText)
                .font(.uMicroBold)
                .foregroundStyle(Color.secondaryLabel)
        }
        .padding(.horizontal, .spacing(.xSmall))
        .padding(.vertical, .spacing(.xxxSmall))
        .background(Color.tertiaryGroupedBackground, in: Capsule())
        .overlay(Capsule().stroke(Color.separator, lineWidth: 0.5))
        .accessibilityLabel("Engine status: \(displayText)")
    }

    private var displayText: String {
        switch status {
        case .ready:
            return "\(modelName) · Ready"
        case .downloading(let percent):
            return "Downloading \(percent)%"
        case .loading:
            return "\(modelName) · Loading…"
        case .offline:
            return "Offline · Mock"
        case .mock:
            return "Mock Engine"
        }
    }

    private var indicatorColor: Color {
        switch status {
        case .ready:
            return Color.positive
        case .downloading, .loading:
            return Color.warning
        case .offline, .mock:
            return Color.secondaryLabel
        }
    }
}

#Preview {
    VStack(spacing: .spacing(.small)) {
        UEngineStatusBadge(modelName: "Gemma 3 1B", status: .ready)
        UEngineStatusBadge(modelName: "Gemma 3 1B", status: .downloading(percent: 45))
        UEngineStatusBadge(modelName: "Gemma 3 1B", status: .loading)
        UEngineStatusBadge(modelName: "", status: .offline)
        UEngineStatusBadge(modelName: "", status: .mock)
    }
    .padding()
}
