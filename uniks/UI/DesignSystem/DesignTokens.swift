//
//  DesignTokens.swift
//  uniks
//
//  Single source of truth for spacing, radii, and semantic colors.
//  Views must not hardcode these values.
//

import SwiftUI

// MARK: - Spacing

enum Spacing: CGFloat {
    case xxxSmall = 2
    case xxSmall = 4
    case xSmall = 8
    case small = 12
    case medium = 16
    case large = 20
    case xLarge = 24
    case xxLarge = 32
    case xxxLarge = 48
}

extension CGFloat {
    static func spacing(_ token: Spacing) -> CGFloat {
        token.rawValue
    }
}

// MARK: - Radius

enum Radius: CGFloat {
    case small = 6
    case medium = 10
    case large = 16
    static let pill: CGFloat = 999
}

extension CGFloat {
    static func radius(_ token: Radius) -> CGFloat {
        token.rawValue
    }
}

// MARK: - Colors

extension Color {
    /// Primary label color (adapts to light/dark).
    static let primaryLabel = Color.primary

    /// Secondary label color.
    static let secondaryLabel = Color.secondary

    /// App accent color.
    static let accent = Color.accentColor

    /// Positive / success state.
    static let positive = Color.green

    /// Negative / error state.
    static let negative = Color.red

    /// Warning / caution state.
    static let warning = Color.orange

    /// Background for grouped content (lists, forms).
    #if os(iOS)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    #elseif os(macOS)
    static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    #endif

    /// Background for secondary grouped surfaces (cards, rows).
    #if os(iOS)
    static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    #elseif os(macOS)
    static let secondaryGroupedBackground = Color(nsColor: .controlBackgroundColor).opacity(0.8)
    #endif

    /// Background for tertiary grouped surfaces (chips, tags).
    static let tertiaryGroupedBackground = Color.gray.opacity(0.08)

    /// Separator and divider color.
    static let separator = Color.gray.opacity(0.15)

    /// Returns a specific color based on the category name for consistent visual styling.
    static func categoryColor(for categoryName: String?) -> Color {
        guard let name = categoryName?.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return .secondaryLabel
        }

        switch name {
        case "fitness", "sport", "workout", "exercise", "run", "gym":
            return .green
        case "health", "medical", "symptom", "medicine", "pill":
            return .orange
        case "reading", "study", "learning", "education", "book":
            return .purple
        case "vehicle", "car", "fuel", "drive", "travel", "transport":
            return .blue
        case "finance", "money", "spent", "cost", "income", "buy":
            return .yellow
        case "diet", "food", "nutrition", "water", "drink", "meal":
            return .teal
        default:
            let colors: [Color] = [.blue, .purple, .teal, .green, .orange, .pink, .indigo]
            let index = abs(name.hashValue) % colors.count
            return colors[index]
        }
    }
}

// MARK: - Premium Gradients

enum Gradients {
    static let brand = LinearGradient(
        colors: [Color.accentColor, Color(red: 0.62, green: 0.38, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let success = LinearGradient(
        colors: [Color.green, Color(red: 0.18, green: 0.7, blue: 0.35)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let warning = LinearGradient(
        colors: [Color.orange, Color(red: 0.98, green: 0.74, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let negative = LinearGradient(
        colors: [Color.red, Color(red: 0.9, green: 0.2, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let pending = LinearGradient(
        colors: [Color.secondary.opacity(0.6), Color.secondary.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
