//
//  DesignTokens.swift
//  uniks
//
//  Single source of truth for spacing, radii, and semantic colors.
//  Views must not hardcode these values.
//

import SwiftUI

// This file is the canonical source of literal SwiftUI colors; all other views must use the exported tokens.
// swiftlint:disable literal_color

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

// MARK: - Sizing

/// Shared one-off dimensions that do not fit the spacing or radius token scales.
/// Prefer these over magic numbers; if a value is truly unique, document it with
/// `// swiftlint:disable:next hardcoded_frame_size`.
enum Sizing: CGFloat {
    case categoryIndicatorWidth = 4
    case categoryIconSize = 24
    case progressBarHeight = 8
    case saveButtonProgressWidth = 44
    case saveButtonProgressHeight = 20
}

extension CGFloat {
    static func sizing(_ constant: Sizing) -> CGFloat {
        constant.rawValue
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

    /// Faint separator for subtle dividers.
    static let separatorFaint = Color.gray.opacity(0.3)

    /// Very faint separator for hairline borders.
    static let separatorVeryFaint = Color.gray.opacity(0.2)

    /// Faint secondary label for inactive indicators.
    static let secondaryLabelFaint = Color.secondaryLabel.opacity(0.2)

    /// Muted secondary label for de-emphasized body text.
    static let secondaryLabelMuted = Color.secondaryLabel.opacity(0.85)

    /// Subtle secondary label for hint text.
    static let secondaryLabelSubtle = Color.secondaryLabel.opacity(0.8)

    // MARK: - Brand Palette

    static let brandBlue = Color.blue
    static let brandPurple = Color.purple
    static let brandOrange = Color.orange
    static let brandRed = Color.red
    static let brandYellow = Color.yellow
    static let brandTeal = Color.teal

    static let brandBlueGlowStrong = Color.brandBlue.opacity(0.12)
    static let brandBlueGlowMedium = Color.brandBlue.opacity(0.1)
    static let brandBlueGlowSoft = Color.brandBlue.opacity(0.08)
    static let brandBlueBackground = Color.brandBlue.opacity(0.04)
    static let brandBlueBorder = Color.brandBlue.opacity(0.12)
    static let brandBlueShadow = Color.brandBlue.opacity(0.3)
    static let brandBlueShadowSoft = Color.brandBlue.opacity(0.2)

    static let brandPurpleGlowMedium = Color.brandPurple.opacity(0.1)
    static let brandPurpleMuted = Color.brandPurple.opacity(0.5)
    static let brandRedGlowSoft = Color.brandRed.opacity(0.08)

    // MARK: - State Variants

    static let onAccent = Color.white
    static let accentSubtle = Color.accent.opacity(0.08)
    static let accentSoft = Color.accent.opacity(0.12)
    static let accentMuted = Color.accent.opacity(0.4)
    static let accentGlow = Color.accent.opacity(0.2)

    static let positiveSubtle = Color.positive.opacity(0.08)
    static let negativeSubtle = Color.negative.opacity(0.08)

    static let tertiaryGroupedBackgroundFaint = Color.tertiaryGroupedBackground.opacity(0.5)

    // MARK: - Surfaces

    static let elevatedBackground = Color.white
    static let glassBackground = Color.white.opacity(0.6)
    static let cardBackgroundLight = Color.white.opacity(0.85)
    static let cardBackgroundDark = Color.black.opacity(0.15)
    static let codeBackground = Color.black.opacity(0.2)
    static let codeBackgroundDark = Color.black.opacity(0.3)

    // MARK: - Shadows

    static let shadowBase = Color.black
    static let shadowVerySubtle = Color.black.opacity(0.02)
    static let shadowSubtle = Color.black.opacity(0.03)
    static let shadowLight = Color.black.opacity(0.04)
    static let shadowMedium = Color.black.opacity(0.08)
    static let shadowHeavy = Color.black.opacity(0.25)

    /// Returns a specific color based on the category name for consistent visual styling.
    /// Checks for user-customized colors first, falls back to built-in mapping.
    static func categoryColor(for categoryName: String?) -> Color {
        guard let name = categoryName?.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return .secondaryLabel
        }

        // Check user-customized colors
        if let customIndex = CategoryColorStore.colorIndex(for: name) {
            return CategoryColorStore.palette[customIndex]
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

/// Persists user-customized category color choices.
enum CategoryColorStore {
    private static let key = "uniks.categoryColors"

    /// Available palette for category customization.
    static let palette: [Color] = [
        .blue, .purple, .teal, .green, .orange, .pink, .indigo, .red, .yellow, .mint
    ]

    /// Returns the stored color palette index for a category, or nil for default.
    static func colorIndex(for category: String) -> Int? {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] else {
            return nil
        }
        return dict[category.lowercased()]
    }

    /// Sets a color palette index for a category.
    static func setColor(index: Int, for category: String) {
        var dict = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int]) ?? [:]
        dict[category.lowercased()] = index
        UserDefaults.standard.set(dict, forKey: key)
    }

    /// Removes custom color for a category (reverts to default).
    static func removeColor(for category: String) {
        var dict = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int]) ?? [:]
        dict.removeValue(forKey: category.lowercased())
        UserDefaults.standard.set(dict, forKey: key)
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

    static let logo = LinearGradient(
        colors: [Color.brandBlue, Color.brandPurple, Color.brandOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hero = LinearGradient(
        colors: [Color.brandBlue, Color.brandPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let brandArea = LinearGradient(
        colors: [Color.accent.opacity(0.3), Color.accent.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func area(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// swiftlint:enable literal_color
