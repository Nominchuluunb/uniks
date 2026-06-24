//
//  UChip.swift
//  uniks
//
//  Reusable chip for categories, values, and tags.
//

import SwiftUI

struct UChip: View {
    enum Style {
        case category
        case value
        case tag
        case neutral
    }

    let text: String
    let style: Style

    var body: some View {
        HStack(spacing: .spacing(.xxxSmall)) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.8)
            }
            Text(text)
        }
        .chipStyle(background: backgroundColor, foreground: foregroundColor)
    }

    private var iconName: String? {
        switch style {
        case .category:
            return Icons.category
        case .value:
            return Icons.value
        case .tag:
            return Icons.tag
        case .neutral:
            return nil
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .category:
            return Color.accent.opacity(0.08)
        case .value:
            return Color.positive.opacity(0.08)
        case .tag:
            return Color.tertiaryGroupedBackground
        case .neutral:
            return Color.secondaryGroupedBackground
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .category:
            return Color.accent
        case .value:
            return Color.positive
        case .tag, .neutral:
            return Color.secondaryLabel
        }
    }
}

#Preview {
    UFlowLayout {
        UChip(text: "Running", style: .category)
        UChip(text: "5 km", style: .value)
        UChip(text: "morning", style: .tag)
    }
    .padding()
}
